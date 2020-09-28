// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB
import Keychain
import Mastodon
import Secrets

public enum IdentityDatabaseError: Error {
    case identityNotFound
}

public struct IdentityDatabase {
    private let databaseWriter: DatabaseWriter

    public init(inMemory: Bool, keychain: Keychain.Type) throws {
        if inMemory {
            databaseWriter = DatabaseQueue()
        } else {
            let path = try FileManager.default.databaseDirectoryURL(name: Self.name).path
            var configuration = Configuration()

            configuration.prepareDatabase {
                try $0.usePassphrase(Secrets.databaseKey(identityID: nil, keychain: keychain))
            }

            databaseWriter = try DatabasePool(path: path, configuration: configuration)
        }

        try migrate()
    }
}

public extension IdentityDatabase {
    func createIdentity(id: UUID, url: URL, authenticated: Bool, pending: Bool) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(
            updates: IdentityRecord(
                id: id,
                url: url,
                authenticated: authenticated,
                pending: pending,
                lastUsedAt: Date(),
                preferences: Identity.Preferences(),
                instanceURI: nil,
                lastRegisteredDeviceToken: nil,
                pushSubscriptionAlerts: .initial)
                .save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func deleteIdentity(id: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: IdentityRecord.filter(Column("id") == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func updateLastUsedAt(identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try IdentityRecord
                .filter(Column("id") == identityID)
                .updateAll($0, Column("lastUsedAt").set(to: Date()))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updateInstance(_ instance: Instance, forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try Identity.Instance(
                uri: instance.uri,
                streamingAPI: instance.urls.streamingApi,
                title: instance.title,
                thumbnail: instance.thumbnail)
                .save($0)
            try IdentityRecord
                .filter(Column("id") == identityID)
                .updateAll($0, Column("instanceURI").set(to: instance.uri))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updateAccount(_ account: Account, forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(
            updates: Identity.Account(
                id: account.id,
                identityID: identityID,
                username: account.username,
                displayName: account.displayName,
                url: account.url,
                avatar: account.avatar,
                avatarStatic: account.avatarStatic,
                header: account.header,
                headerStatic: account.headerStatic,
                emojis: account.emojis)
                .save)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func confirmIdentity(id: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            try IdentityRecord
                .filter(Column("id") == id)
                .updateAll($0, Column("pending").set(to: false))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updatePreferences(_ preferences: Mastodon.Preferences,
                           forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            guard let storedPreferences = try IdentityRecord.filter(Column("id") == identityID)
                    .fetchOne($0)?
                    .preferences else {
                throw IdentityDatabaseError.identityNotFound
            }

            try Self.writePreferences(storedPreferences.updated(from: preferences), id: identityID)($0)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updatePreferences(_ preferences: Identity.Preferences,
                           forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher(updates: Self.writePreferences(preferences, id: identityID))
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func updatePushSubscription(alerts: PushSubscription.Alerts,
                                deviceToken: Data? = nil,
                                forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseWriter.writePublisher {
            let data = try IdentityRecord.databaseJSONEncoder(for: "pushSubscriptionAlerts").encode(alerts)

            try IdentityRecord
                .filter(Column("id") == identityID)
                .updateAll($0, Column("pushSubscriptionAlerts").set(to: data))

            if let deviceToken = deviceToken {
                try IdentityRecord
                    .filter(Column("id") == identityID)
                    .updateAll($0, Column("lastRegisteredDeviceToken").set(to: deviceToken))
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func identityObservation(id: UUID, immediate: Bool) -> AnyPublisher<Identity, Error> {
        ValueObservation.tracking(
            IdentityRecord
                .filter(Column("id") == id)
                .identityResultRequest
                .fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter, scheduling: immediate ? .immediate : .async(onQueue: .main))
            .tryMap {
                guard let result = $0 else { throw IdentityDatabaseError.identityNotFound }

                return Identity(result: result)
            }
            .eraseToAnyPublisher()
    }

    func identitiesObservation() -> AnyPublisher<[Identity], Error> {
        ValueObservation.tracking(
            IdentityRecord
                .order(Column("lastUsedAt").desc)
                .identityResultRequest
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { $0.map(Identity.init(result:)) }
            .eraseToAnyPublisher()
    }

    func recentIdentitiesObservation(excluding: UUID) -> AnyPublisher<[Identity], Error> {
        ValueObservation.tracking(
            IdentityRecord
                .order(Column("lastUsedAt").desc)
                .identityResultRequest
                .filter(Column("id") != excluding)
                .limit(9)
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { $0.map(Identity.init(result:)) }
            .eraseToAnyPublisher()
    }

    func immediateMostRecentlyUsedIdentityIDObservation() -> AnyPublisher<UUID?, Error> {
        ValueObservation.tracking(IdentityRecord.select(Column("id")).order(Column("lastUsedAt").desc).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter, scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    func identitiesWithOutdatedDeviceTokens(deviceToken: Data) -> AnyPublisher<[Identity], Error> {
        databaseWriter.readPublisher(
            value: IdentityRecord
                .order(Column("lastUsedAt").desc)
                .identityResultRequest
                .filter(Column("lastRegisteredDeviceToken") != deviceToken)
                .fetchAll)
            .map { $0.map(Identity.init(result:)) }
            .eraseToAnyPublisher()
    }
}

private extension IdentityDatabase {
    static let name = "Identity"

    static func writePreferences(_ preferences: Identity.Preferences, id: UUID) -> (Database) throws -> Void {
        {
            let data = try IdentityRecord.databaseJSONEncoder(for: "preferences").encode(preferences)

            try IdentityRecord
                .filter(Column("id") == id)
                .updateAll($0, Column("preferences").set(to: data))
        }
    }

    func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createIdentities") { db in
            try db.create(table: "instance", ifNotExists: true) { t in
                t.column("uri", .text).notNull().primaryKey(onConflict: .replace)
                t.column("streamingAPI", .text)
                t.column("title", .text)
                t.column("thumbnail", .text)
            }

            try db.create(table: "identityRecord", ifNotExists: true) { t in
                t.column("id", .text).indexed().notNull().primaryKey(onConflict: .replace)
                t.column("url", .text).notNull()
                t.column("authenticated", .boolean).notNull()
                t.column("pending", .boolean).notNull()
                t.column("lastUsedAt", .datetime).notNull()
                t.column("instanceURI", .text)
                    .references("instance", column: "uri")
                t.column("preferences", .blob).notNull()
                t.column("pushSubscriptionAlerts", .blob).notNull()
                t.column("lastRegisteredDeviceToken", .blob)
            }

            try db.create(table: "account", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("identityID", .text).notNull()
                    .references("identityRecord", column: "id", onDelete: .cascade)
                t.column("username", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("url", .text).notNull()
                t.column("avatar", .text).notNull()
                t.column("avatarStatic", .text).notNull()
                t.column("header", .text).notNull()
                t.column("headerStatic", .text).notNull()
                t.column("emojis", .blob).notNull()
            }
        }

        try migrator.migrate(databaseWriter)
    }
}
