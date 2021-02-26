// Copyright © 2020 Metabolist. All rights reserved.

import GRDB

extension ContentDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("0.1.0") { db in
            try db.create(table: "accountRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("username", .text).notNull()
                t.column("acct", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("locked", .boolean).notNull()
                t.column("createdAt", .date).notNull()
                t.column("followersCount", .integer).notNull()
                t.column("followingCount", .integer).notNull()
                t.column("statusesCount", .integer).notNull()
                t.column("note", .text).notNull()
                t.column("url", .text).notNull()
                t.column("avatar", .text).notNull()
                t.column("avatarStatic", .text).notNull()
                t.column("header", .text).notNull()
                t.column("headerStatic", .text).notNull()
                t.column("fields", .blob).notNull()
                t.column("emojis", .blob).notNull()
                t.column("bot", .boolean).notNull()
                t.column("discoverable", .boolean)
                t.column("movedId", .text).references("accountRecord", onDelete: .cascade)
            }

            try db.create(table: "relationship") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                    .references("accountRecord", onDelete: .cascade)
                t.column("following", .boolean).notNull()
                t.column("requested", .boolean).notNull()
                t.column("endorsed", .boolean).notNull()
                t.column("followedBy", .boolean).notNull()
                t.column("muting", .boolean).notNull()
                t.column("mutingNotifications", .boolean).notNull()
                t.column("showingReblogs", .boolean).notNull()
                t.column("blocking", .boolean).notNull()
                t.column("domainBlocking", .boolean).notNull()
                t.column("blockedBy", .boolean).notNull()
                t.column("note", .text).notNull()
            }

            try db.create(table: "identityProofRecord") { t in
                t.column("accountId", .text).notNull().references("accountRecord", onDelete: .cascade)
                t.column("provider", .text).notNull()
                t.column("providerUsername", .text).notNull()
                t.column("profileUrl", .text).notNull()
                t.column("proofUrl", .text).notNull()
                t.column("updatedAt", .date).notNull()

                t.primaryKey(["accountId", "provider"], onConflict: .replace)
            }

            try db.create(table: "featuredTagRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("name", .text).notNull()
                t.column("url", .text).notNull()
                t.column("statusesCount", .integer).notNull()
                t.column("lastStatusAt", .date).notNull()
                t.column("accountId", .text).notNull().references("accountRecord", onDelete: .cascade)
            }

            try db.create(table: "statusRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("uri", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("accountId", .text).notNull().references("accountRecord", onDelete: .cascade)
                t.column("content", .text).notNull()
                t.column("visibility", .text).notNull()
                t.column("sensitive", .boolean).notNull()
                t.column("spoilerText", .text).notNull()
                t.column("mediaAttachments", .blob).notNull()
                t.column("mentions", .blob).notNull()
                t.column("tags", .blob).notNull()
                t.column("emojis", .blob).notNull()
                t.column("reblogsCount", .integer).notNull()
                t.column("favouritesCount", .integer).notNull()
                t.column("repliesCount", .integer).notNull()
                t.column("application", .blob)
                t.column("url", .text)
                t.column("inReplyToId", .text)
                t.column("inReplyToAccountId", .text)
                t.column("reblogId", .text).references("statusRecord", onDelete: .cascade)
                t.column("poll", .blob)
                t.column("card", .blob)
                t.column("language", .text)
                t.column("text", .text)
                t.column("favourited", .boolean).notNull()
                t.column("reblogged", .boolean).notNull()
                t.column("muted", .boolean).notNull()
                t.column("bookmarked", .boolean).notNull()
                t.column("pinned", .boolean)
            }

            try db.create(table: "statusShowContentToggle") { t in
                t.column("statusId", .text).primaryKey().references("statusRecord", onDelete: .cascade)
            }

            try db.create(table: "statusShowAttachmentsToggle") { t in
                t.column("statusId", .text).primaryKey().references("statusRecord", onDelete: .cascade)
            }

            try db.create(table: "timelineRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("listId", .text)
                t.column("listTitle", .text).indexed().collate(.localizedCaseInsensitiveCompare)
                t.column("tag", .text)
                t.column("accountId", .text)
                t.column("profileCollection", .text)
            }

            try db.create(table: "loadMoreRecord") { t in
                t.column("timelineId").notNull().references("timelineRecord", onDelete: .cascade)
                t.column("afterStatusId", .text).notNull()
                t.column("beforeStatusId", .text).notNull()

                t.primaryKey(["timelineId", "afterStatusId"], onConflict: .replace)
            }

            try db.create(table: "timelineStatusJoin") { t in
                t.column("timelineId", .text).indexed().notNull()
                    .references("timelineRecord", onDelete: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", onDelete: .cascade)
                t.column("order", .integer)

                t.primaryKey(["timelineId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "filter") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("phrase", .text).notNull()
                t.column("context", .blob).notNull()
                t.column("expiresAt", .date).indexed()
                t.column("irreversible", .boolean).notNull()
                t.column("wholeWord", .boolean).notNull()
            }

            try db.create(table: "emoji") { t in
                t.column("shortcode", .text)
                    .primaryKey(onConflict: .replace)
                    .collate(.localizedCaseInsensitiveCompare)
                    .notNull()
                t.column("staticUrl", .text).notNull()
                t.column("url", .text).notNull()
                t.column("visibleInPicker", .boolean).notNull()
                t.column("category", .text)
            }

            try db.create(table: "emojiUse") { t in
                t.column("emoji", .text).primaryKey(onConflict: .replace)
                t.column("system", .boolean).notNull()
                t.column("lastUse", .datetime).notNull()
                t.column("count", .integer).notNull()
            }

            try db.create(table: "announcement") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("content", .text).notNull()
                t.column("startsAt", .datetime)
                t.column("endsAt", .datetime)
                t.column("allDay", .boolean).notNull()
                t.column("publishedAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("read", .boolean).notNull()
                t.column("mentions", .blob).notNull()
                t.column("tags", .blob).notNull()
                t.column("emojis", .blob).notNull()
                t.column("reactions", .blob).notNull()
            }

            try db.create(table: "conversationRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("unread", .boolean).notNull()
                t.column("lastStatusId", .text).references("statusRecord", onDelete: .cascade)
            }

            try db.create(table: "conversationAccountJoin") { t in
                t.column("conversationId", .text).indexed().notNull()
                    .references("conversationRecord", onDelete: .cascade)
                t.column("accountId", .text).indexed().notNull()
                    .references("accountRecord", onDelete: .cascade)

                t.primaryKey(["conversationId", "accountId"], onConflict: .replace)
            }

            try db.create(table: "lastReadIdRecord") { t in
                t.column("markerTimeline", .text).primaryKey(onConflict: .replace)
                t.column("id", .text).notNull()
            }

            try db.create(table: "notificationRecord") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("type", .text).notNull()
                t.column("accountId", .text).notNull().references("accountRecord", onDelete: .cascade)
                t.column("createdAt", .datetime).notNull()
                t.column("statusId").references("statusRecord", onDelete: .cascade)
            }

            try db.create(table: "instanceRecord") { t in
                t.column("uri", .text).primaryKey(onConflict: .replace)
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("shortDescription", .text)
                t.column("email", .text).notNull()
                t.column("version", .text).notNull()
                t.column("languages", .blob).notNull()
                t.column("registrations", .boolean).notNull()
                t.column("approvalRequired", .boolean).notNull()
                t.column("invitesEnabled", .boolean).notNull()
                t.column("urls", .blob).notNull()
                t.column("stats", .blob).notNull()
                t.column("thumbnail", .text)
                t.column("contactAccountId", .text).references("accountRecord", onDelete: .cascade)
                t.column("maxTootChars", .integer)
            }

            try db.create(table: "statusAncestorJoin") { t in
                t.column("parentId", .text).indexed().notNull()
                    .references("statusRecord", onDelete: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", onDelete: .cascade)
                t.column("order", .integer).notNull()

                t.primaryKey(["parentId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "statusDescendantJoin") { t in
                t.column("parentId", .text).indexed().notNull()
                    .references("statusRecord", onDelete: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", onDelete: .cascade)
                t.column("order", .integer).notNull()

                t.primaryKey(["parentId", "statusId"], onConflict: .replace)
            }

            try db.create(table: "accountPinnedStatusJoin") { t in
                t.column("accountId", .text).indexed().notNull()
                    .references("accountRecord", onDelete: .cascade)
                t.column("statusId", .text).indexed().notNull()
                    .references("statusRecord", onDelete: .cascade)
                t.column("order", .integer).notNull()

                t.primaryKey(["accountId", "statusId"], onConflict: .replace)
            }
        }

        migrator.registerMigration("1.0.0") { db in
            try db.create(table: "accountList") { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
            }

            try db.create(table: "accountListJoin") { t in
                t.column("accountListId", .text).indexed().notNull()
                    .references("accountList", onDelete: .cascade)
                t.column("accountId", .text).indexed().notNull()
                    .references("accountRecord", onDelete: .cascade)
                t.column("order", .integer).notNull()

                t.primaryKey(["accountListId", "accountId", "order"], onConflict: .replace)
            }
        }

        migrator.registerMigration("1.0.0-pk-fix") { db in
            try db.create(table: "new_accountListJoin") { t in
                t.column("accountListId", .text).indexed().notNull()
                    .references("accountList", onDelete: .cascade)
                t.column("accountId", .text).indexed().notNull()
                    .references("accountRecord", onDelete: .cascade)
                t.column("order", .integer).notNull()

                t.primaryKey(["accountListId", "accountId"], onConflict: .replace)
            }

            try db.execute(sql: "INSERT INTO new_accountListJoin SELECT * FROM accountListJoin")
            try db.drop(table: "accountListJoin")
            try db.rename(table: "new_accountListJoin", to: "accountListJoin")
        }

        migrator.registerMigration("1.0.0-lridr-column-rename") { db in
            try db.alter(table: "lastReadIdRecord") { t in
                t.rename(column: "markerTimeline", to: "timelineId")
            }
        }

        migrator.registerMigration("1.0.0-notifying") { db in
            try db.alter(table: "relationship") { t in
                t.add(column: "notifying", .boolean)
            }
        }

        return migrator
    }
}
