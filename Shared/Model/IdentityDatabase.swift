// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import GRDB

struct IdentityDatabase {
    private let databaseQueue: DatabaseQueue

    init(inMemory: Bool = false) throws {
        guard
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(
                .documentDirectory,
                .userDomainMask, true)
                .first
        else { throw DatabaseError.documentsDirectoryNotFound }

        if inMemory {
            databaseQueue = DatabaseQueue()
        } else {
            databaseQueue = try DatabaseQueue(path: "\(documentsDirectory)/IdentityDatabase.sqlite3")
        }

        try Self.migrate(databaseQueue)
    }
}

extension IdentityDatabase {
    func createIdentity(id: String, url: URL) -> AnyPublisher<Void, Error> {
        databaseQueue.writePublisher(updates: StoredIdentity(id: id, url: url, instanceURI: nil).save)
            .eraseToAnyPublisher()
    }

    func updateInstance(_ instance: Instance, forIdentityID identityID: String) -> AnyPublisher<Void, Error> {
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
        .eraseToAnyPublisher()
    }

    func updateAccount(_ account: Account, forIdentityID identityID: String) -> AnyPublisher<Void, Error> {
        databaseQueue.writePublisher(
            updates: Identity.Account(
                id: account.id,
                identityID: identityID,
                username: account.username,
                url: account.url,
                avatar: account.avatar,
                avatarStatic: account.avatarStatic,
                header: account.header,
                headerStatic: account.headerStatic)
                .save)
            .eraseToAnyPublisher()
    }

    func identityObservation(id: String) -> AnyPublisher<Identity?, Error> {
        ValueObservation.tracking(
            StoredIdentity
                .filter(Column("id") == id)
                .including(optional: StoredIdentity.instance)
                .including(optional: StoredIdentity.account)
                .asRequest(of: IdentityResult.self)
                .fetchOne)
            .removeDuplicates()
            .publisher(in: databaseQueue, scheduling: .immediate)
            .map {
                guard let result = $0 else { return nil }

                return Identity(result: result)
            }
            .eraseToAnyPublisher()
    }
}

private extension IdentityDatabase {
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
                t.column("instanceURI", .text)
                    .indexed()
                    .references("instance", column: "uri")
            }

            try db.create(table: "account", ifNotExists: true) { t in
                t.column("id", .text).notNull().primaryKey(onConflict: .replace)
                t.column("identityID", .text)
                    .notNull()
                    .indexed()
                    .references("storedIdentity", column: "id", onDelete: .cascade)
                t.column("username", .text).notNull()
                t.column("url", .text).notNull()
                t.column("avatar", .text).notNull()
                t.column("avatarStatic", .text).notNull()
                t.column("header", .text).notNull()
                t.column("headerStatic", .text).notNull()
            }
        }

        try migrator.migrate(writer)
    }
}

private struct StoredIdentity: Codable, Hashable, TableRecord, FetchableRecord, PersistableRecord {
    let id: String
    let url: URL
    let instanceURI: String?
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
}

private extension Identity {
    init(result: IdentityResult) {
        self.init(id: result.identity.id, url: result.identity.url, instance: result.instance, account: result.account)
    }
}

extension Identity.Instance: TableRecord, FetchableRecord, PersistableRecord {}

extension Identity.Account: TableRecord, FetchableRecord, PersistableRecord {}