// Copyright © 2020 Metabolist. All rights reserved.

import GRDB

extension IdentityDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("0.1.0") { db in
            try db.create(table: "instance", ifNotExists: true) { t in
                t.column("uri", .text).primaryKey(onConflict: .replace)
                t.column("streamingAPI", .text).notNull()
                t.column("title", .text).notNull()
                t.column("thumbnail", .text)
                t.column("version", .text).notNull()
                t.column("maxTootChars", .integer)
            }

            try db.create(table: "identityRecord", ifNotExists: true) { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("url", .text).notNull()
                t.column("authenticated", .boolean).notNull()
                t.column("pending", .boolean).notNull()
                t.column("lastUsedAt", .datetime).notNull()
                t.column("instanceURI", .text).references("instance")
                t.column("preferences", .blob).notNull()
                t.column("pushSubscriptionAlerts", .blob).notNull()
                t.column("lastRegisteredDeviceToken", .blob)
            }

            try db.create(table: "account", ifNotExists: true) { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("identityId", .text).notNull()
                    .references("identityRecord", onDelete: .cascade)
                t.column("username", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("url", .text).notNull()
                t.column("avatar", .text).notNull()
                t.column("avatarStatic", .text).notNull()
                t.column("header", .text).notNull()
                t.column("headerStatic", .text).notNull()
                t.column("emojis", .blob).notNull()
                t.column("followRequestCount", .integer).notNull()
            }
        }

        migrator.registerMigration("1.2.0-pk-fix") { db in
            try db.create(table: "new_account") { t in
                t.column("id", .text).notNull()
                t.column("identityId", .text).notNull()
                    .references("identityRecord", onDelete: .cascade)
                t.column("username", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("url", .text).notNull()
                t.column("avatar", .text).notNull()
                t.column("avatarStatic", .text).notNull()
                t.column("header", .text).notNull()
                t.column("headerStatic", .text).notNull()
                t.column("emojis", .blob).notNull()
                t.column("followRequestCount", .integer).notNull()

                t.primaryKey(["id", "identityId"], onConflict: .replace)
            }

            try db.execute(sql: "INSERT INTO new_account SELECT * FROM account")
            try db.drop(table: "account")
            try db.rename(table: "new_account", to: "account")
        }

        return migrator
    }
}
