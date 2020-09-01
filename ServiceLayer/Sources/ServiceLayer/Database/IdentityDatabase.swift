// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import GRDB
import Mastodon

enum IdentityDatabaseError: Error {
    case identityNotFound
}

struct IdentityDatabase {
    private let databaseQueue: DatabaseQueue

    init(environment: AppEnvironment) throws {
        guard
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(
                .documentDirectory,
                .userDomainMask, true)
                .first
        else { throw DatabaseError.documentsDirectoryNotFound }

        if environment.inMemoryContent {
            databaseQueue = DatabaseQueue()
        } else {
            databaseQueue = try DatabaseQueue(path: "\(documentsDirectory)/IdentityDatabase.sqlite3")
        }

        try Self.migrate(databaseQueue)

        if let fixture = environment.identityFixture {
            try populate(fixture: fixture)
        }
    }
}

extension IdentityDatabase {
    func createIdentity(id: UUID, url: URL) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(
            updates: StoredIdentity(
                id: id,
                url: url,
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
        return databaseQueue.writePublisher(updates: StoredIdentity.filter(Column("id") == id).deleteAll)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func updateLastUsedAt(identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            try StoredIdentity
                .filter(Column("id") == identityID)
                .updateAll($0, Column("lastUsedAt").set(to: Date()))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updateInstance(_ instance: Instance, forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            try Identity.Instance(
                uri: instance.uri,
                streamingAPI: instance.urls.streamingApi,
                title: instance.title,
                thumbnail: instance.thumbnail)
                .save($0)
            try StoredIdentity
                .filter(Column("id") == identityID)
                .updateAll($0, Column("instanceURI").set(to: instance.uri))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updateAccount(_ account: Account, forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher(
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

    func updatePreferences(_ preferences: Identity.Preferences,
                           forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            let data = try StoredIdentity.databaseJSONEncoder(for: "preferences").encode(preferences)

            try StoredIdentity
                .filter(Column("id") == identityID)
                .updateAll($0, Column("preferences").set(to: data))
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func updatePushSubscription(alerts: PushSubscription.Alerts,
                                deviceToken: String? = nil,
                                forIdentityID identityID: UUID) -> AnyPublisher<Never, Error> {
        databaseQueue.writePublisher {
            let data = try StoredIdentity.databaseJSONEncoder(for: "pushSubscriptionAlerts").encode(alerts)

            try StoredIdentity
                .filter(Column("id") == identityID)
                .updateAll($0, Column("pushSubscriptionAlerts").set(to: data))

            if let deviceToken = deviceToken {
                try StoredIdentity
                    .filter(Column("id") == identityID)
                    .updateAll($0, Column("lastRegisteredDeviceToken").set(to: deviceToken))
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    func identityObservation(id: UUID) -> AnyPublisher<Identity, Error> {
        ValueObservation.tracking(
            StoredIdentity
                .filter(Column("id") == id)
                .including(optional: StoredIdentity.instance)
                .including(optional: StoredIdentity.account)
                .asRequest(of: IdentityResult.self)
                .fetchOne)
            .removeDuplicates()
            .publisher(in: databaseQueue, scheduling: .immediate)
            .tryMap {
                guard let result = $0 else { throw IdentityDatabaseError.identityNotFound }

                return Identity(result: result)
            }
            .eraseToAnyPublisher()
    }

    func identitiesObservation() -> AnyPublisher<[Identity], Error> {
        ValueObservation.tracking(Self.identitiesRequest().fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue, scheduling: .immediate)
            .map { $0.map(Identity.init(result:)) }
            .eraseToAnyPublisher()
    }

    func recentIdentitiesObservation(excluding: UUID) -> AnyPublisher<[Identity], Error> {
        ValueObservation.tracking(
            Self.identitiesRequest()
                .filter(Column("id") != excluding)
                .limit(9)
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseQueue, scheduling: .immediate)
            .map { $0.map(Identity.init(result:)) }
            .eraseToAnyPublisher()
    }

    func mostRecentlyUsedIdentityIDObservation() -> AnyPublisher<UUID?, Error> {
        ValueObservation.tracking(StoredIdentity.select(Column("id")).order(Column("lastUsedAt").desc).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    func identitiesWithOutdatedDeviceTokens(deviceToken: String) -> AnyPublisher<[Identity], Error> {
        databaseQueue.readPublisher(
            value: Self.identitiesRequest()
                .filter(Column("lastRegisteredDeviceToken") != deviceToken)
                .fetchAll)
            .map { $0.map(Identity.init(result:)) }
            .eraseToAnyPublisher()
    }
}

private extension IdentityDatabase {
    private static func identitiesRequest() -> QueryInterfaceRequest<IdentityResult> {
        StoredIdentity
            .order(Column("lastUsedAt").desc)
            .including(optional: StoredIdentity.instance)
            .including(optional: StoredIdentity.account)
            .asRequest(of: IdentityResult.self)
    }

    private static func migrate(_ writer: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createIdentities") { db in
            try db.create(table: "instance", ifNotExists: true) { t in
                t.column("uri", .text).notNull().primaryKey(onConflict: .replace)
                t.column("streamingAPI", .text)
                t.column("title", .text)
                t.column("thumbnail", .text)
            }

            try db.create(table: "storedIdentity", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("url", .text).notNull()
                t.column("lastUsedAt", .datetime).notNull()
                t.column("instanceURI", .text)
                    .indexed()
                    .references("instance", column: "uri")
                t.column("preferences", .blob).notNull()
                t.column("pushSubscriptionAlerts", .blob).notNull()
                t.column("lastRegisteredDeviceToken", .text)
            }

            try db.create(table: "account", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("identityID", .text)
                    .notNull()
                    .indexed()
                    .references("storedIdentity", column: "id", onDelete: .cascade)
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

        try migrator.migrate(writer)
    }

    func populate(fixture: AppEnvironment.IdentityFixture) throws {
        _ = createIdentity(id: fixture.id, url: fixture.instanceURL)
            .receive(on: ImmediateScheduler.shared)
            .sink { _ in } receiveValue: { _ in }

        if let instance = fixture.instance {
            _ = updateInstance(instance, forIdentityID: fixture.id)
                .receive(on: ImmediateScheduler.shared)
                .sink { _ in } receiveValue: { _ in }
        }

        if let account = fixture.account {
            _ = updateAccount(account, forIdentityID: fixture.id)
                .receive(on: ImmediateScheduler.shared)
                .sink { _ in } receiveValue: { _ in }
        }
    }
}

private struct StoredIdentity: Codable, Hashable, FetchableRecord, PersistableRecord {
    let id: UUID
    let url: URL
    let lastUsedAt: Date
    let preferences: Identity.Preferences
    let instanceURI: String?
    let lastRegisteredDeviceToken: String?
    let pushSubscriptionAlerts: PushSubscription.Alerts
}

extension StoredIdentity {
    static let instance = belongsTo(Identity.Instance.self, key: "instance")
    static let account = hasOne(Identity.Account.self, key: "account")

    var instance: QueryInterfaceRequest<Identity.Instance> {
        request(for: Self.instance)
    }

    var account: QueryInterfaceRequest<Identity.Account> {
        request(for: Self.account)
    }
}

private struct IdentityResult: Codable, Hashable, FetchableRecord {
    let identity: StoredIdentity
    let instance: Identity.Instance?
    let account: Identity.Account?
    let pushSubscriptionAlerts: PushSubscription.Alerts
}

private extension Identity {
    init(result: IdentityResult) {
        self.init(
            id: result.identity.id,
            url: result.identity.url,
            lastUsedAt: result.identity.lastUsedAt,
            preferences: result.identity.preferences,
            instance: result.instance,
            account: result.account,
            lastRegisteredDeviceToken: result.identity.lastRegisteredDeviceToken,
            pushSubscriptionAlerts: result.pushSubscriptionAlerts)
    }
}

extension Identity.Instance: FetchableRecord, PersistableRecord {}

extension Identity.Account: FetchableRecord, PersistableRecord {}
