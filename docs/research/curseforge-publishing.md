# Publishing Ergonomancer on CurseForge, Wago, WoWInterface and GitHub

Researched 2026-09-23. Sources are primary (official docs, policy pages, tool source code) unless marked otherwise. Where only a secondary source exists, the text says so.

## Answer

The most important finding comes first, because it changes the TOC: **WoW Forever is not the 12.1.5 client.** The Forever beta client is version 1.60.1, so its interface number is almost certainly `16001`. Blizzard's own UI source for the Forever branch is labelled `1.60.1` ([Gethe/wow-ui-source `forever` branch commits](https://github.com/Gethe/wow-ui-source/commits/forever)). Wago, CurseForge and the BigWigs packager all treat Forever as its own flavor on the 1.60.x line (see [WoW Forever](#wow-forever)). `12.1.5` is the retail PTR (`wowxptr`), and live retail is `12.1.0` ([wago.tools builds API](https://wago.tools/api/builds)). Ergonomancer's current `## Interface: 120100, 120105` covers retail live and retail PTR, not Forever.

Ordered checklist. **Owner** means only Brian can do it (accounts, tokens, in-game checks). **Repo** means it can be done as a change in this repository.

1. **Owner.** In the Forever client, run `/dump (select(4, GetBuildInfo()))` and note the number. Also check whether the AddOns list marks Ergonomancer as "Out of date". That confirms the interface number (expected `16001`) and shows how the client treats the current TOC.
2. **Repo.** If step 1 gives `16001`, change the TOC to `## Interface: 120100, 120105, 16001`. The packager then tags uploads for both Retail and Forever automatically ([packager `toc_to_type`](https://github.com/BigWigsMods/packager/blob/master/release.sh)).
3. **Repo.** Add a `LICENSE` file (CurseForge requires you to pick a license on the project form). Add `.pkgmeta` and `.github/workflows/release.yml` (examples below).
4. **Owner.** Create the GitHub repo and push. Under Settings > Actions > General, allow workflows read and write permission, or rely on `permissions: contents: write` in the workflow ([packager wiki](https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow)).
5. **Owner.** Make an original 400x400 PNG avatar. Do not use the Blizzard map icon from `## IconTexture:`, because CurseForge rejects copyrighted imagery in avatars ([CurseForge moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)).
6. **Owner.** Create a CurseForge account and a WoW addon project at <https://authors.curseforge.com/#/projects/create/choose-game> ([CurseForge: creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project)).
7. **Repo.** Add `## X-Curse-Project-ID: <id>` to the TOC. The ID is in the "About Project" box on the project page ([packager README](https://github.com/BigWigsMods/packager#customizing-the-build)).
8. **Owner.** Generate a CurseForge API token and store it as the GitHub secret `CF_API_TOKEN` (see [Automated releases](#automated-releases-with-the-bigwigs-packager)).
9. **Owner, optional.** Create a Wago Addons project (sign in with Battle.net or GitHub), copy its 8-character ID, create an API key, and store it as `WAGO_API_TOKEN`. **Repo:** add `## X-Wago-ID: <id>`.
10. **Owner, optional, lowest value.** WoWInterface: upload the first version by hand to get an addon ID, create an API token, and store it as `WOWI_API_TOKEN`. **Repo:** add `## X-WoWI-ID: <id>`. WoWInterface has no Forever flavor.
11. **Owner.** Push a tag such as `v0.6.0`. The workflow builds `Ergonomancer-v0.6.0.zip`, uploads it to each site that has an ID and token, and creates a GitHub release. The first CurseForge file must be Release or Beta, not Alpha, or the project will not sync to the CurseForge app ([CurseForge: file types](https://support.curseforge.com/support/solutions/articles/9000197242-file-project-types-and-additional-fields)).
12. **Owner.** Wait for moderation. CurseForge says to expect contact within 48 to 72 hours. If the status becomes "Changes Required", fix the page and resubmit. Do not delete and re-upload ([CurseForge moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies), [project statuses](https://support.curseforge.com/support/solutions/articles/9000197905-project-statuses-101)).

Recommendation on scope: publish to CurseForge and GitHub releases, and add Wago because it costs one ID and one secret with the same workflow. Skip WoWInterface for now. It lists neither Forever nor 12.1.5, and its game list has only one 12.1 entry ([WoWInterface compatible versions API](https://api.wowinterface.com/addons/compatible.json)).

## CurseForge account and project creation

- Register or log in to a CurseForge account, then open <https://authors.curseforge.com/#/projects/create/choose-game> and choose World of Warcraft ([source](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project)).
- Fields on the form ([same source](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project)):
  - **Name.** Must be unique; a name that is already taken is rejected.
  - **Summary.** Short text shown in listings.
  - **Description.** CurseForge rejects descriptions that are not grammatically correct or do not describe the project. Titles and descriptions must be in English.
  - **Project License.** A dropdown of common licenses, or "Custom".
  - **Class.** The root category. For an addon this is "Addons".
  - **Main category**, plus up to 4 **additional categories**. Irrelevant categories can get the project sent back.
  - **Logo image.**
- The project goes to moderators only after a file is uploaded: "The last step before your project is submitted to moderators for approval is uploading a file" ([source](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project)).
- Author eligibility: you must be of legal age of majority where you live, and you grant Overwolf a royalty-free license to host and distribute the addon ([CurseForge Mod Authors Terms](https://legal.overwolf.com/docs/curseforge/mod-authors-terms/)).

## Moderation and content policies

### Review process and timing

- Every project and file goes through automated checks and manual review ([CurseForge moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)).
- Project statuses: New, Changes Required, Changes Made, Approved, Rejected, Inactive, Abandoned. A rejected project "can not be re-evaluated or approved at a later date". File statuses: Under Review, Approved, Under Manual Review, Rejected, Archived, Deleted ([project statuses](https://support.curseforge.com/support/solutions/articles/9000197905-project-statuses-101)).
- Timing: "our support will contact you within 48-72 hours" ([submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)). Later file updates also go to "Under Review" ([file types](https://support.curseforge.com/support/solutions/articles/9000197242-file-project-types-and-additional-fields)).

### Rules that affect Ergonomancer

From the [CurseForge moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies) unless noted:

- **Naming.** "Names should not contain game name, class name versions, file versions" and so on. Use "Ergonomancer", not "Ergonomancer Forever" or "Ergonomancer 12.1".
- **Description.** It must say what the addon does in the game. Generic statements are not enough. The README's "What it does" section is a good base.
- **Summary.** Ideally one sentence, not copied from the description. The TOC `## Notes:` line works.
- **External downloads.** "External download links for files are not allowed." A link to the GitHub source is not a download link, but do not point users at a zip elsewhere.
- **Donations and personal links.** Donation links (Ko-fi, Patreon), personal websites and cross-hosting links must go at the bottom of the description at a reasonable size. Link badges without promotional material are allowed at the top.
- **Changelog.** "Files must include a change log describing the changes from the previous version." The packager generates one (see [Changelog](#changelog)).
- **Update spam.** Re-uploads without changes, or trivial changes to look active, are not allowed.
- **Avatar.** 400x400, not a solid color, no NSFW, no copyrighted imagery. Avoid WebP because of a known bug.
- **Communication channel.** CurseForge "strongly recommended" giving users a way to report bugs. The GitHub issues page covers this.
- **AI content.** The only AI rule is about showcase images: an AI-generated or AI-edited image that may misrepresent the addon must carry a visible disclaimer. No rule about AI-written code was found in the moderation policies or the [Mod Authors Terms](https://legal.overwolf.com/docs/curseforge/mod-authors-terms/). See [Unconfirmed items](#unconfirmed-items).
- **Obfuscation.** CurseForge's policy pages do not mention obfuscation. Blizzard's policy forbids it: "The programming code of an add-on must in no way be hidden or obfuscated" ([Blizzard UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534)). CurseForge also says projects must follow the game developer's ToS ([moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)). Plain, readable Lua meets both.

### Blizzard's addon policy

The [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534), reposted by Blizzard's Kaivax, applies on every site:

- Addons must be free.
- Code must be visible and not obfuscated.
- Addons must not harm realm performance or other players.
- No advertising inside the addon.
- No donation requests inside the game. A website may ask.
- Content must fit a "T" rating.
- Blizzard can disable any addon functionality.

Ergonomancer already meets these.

## Required project assets

| Asset | Requirement | Source |
| --- | --- | --- |
| Avatar or logo | 400x400 PNG, 1:1, original. No solid color, no copyrighted imagery. Avoid WebP. | [Moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies), [submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips) |
| Summary | Required. About one sentence, in English. | [Creating a project](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project) |
| Description | Required. Must describe the functions. English first. | Same |
| License | Required field. Pick from the dropdown or use "Custom". | Same |
| Categories | One main category is required. Up to 4 additional categories. | Same |
| Screenshots | Recommended for addons, required only for texture packs and Sims projects. | [Creating a project](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project), [submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips) |

Category options on the WoW addons browser include "Quests & Leveling", "Map & Minimap" and "Miscellaneous" ([CurseForge WoW addons](https://www.curseforge.com/wow/addons)). "Quests & Leveling" as the main category, with "Map & Minimap" added, fits what Ergonomancer does.

License: CurseForge does not name a preferred license. For a small open-source addon, MIT is common and permissive. The repo also needs a `LICENSE` file so GitHub shows the terms. Choosing the license is Brian's decision.

Screenshots are the best way to show this addon: the tracker wash, the teal minimap letters and the Nearby (Untracked) section.

## File packaging

### Zip layout

CurseForge's WoW processor enforces this ([file processor errors](https://support.curseforge.com/support/solutions/articles/9000210425-curseforge-file-processor-errors-per-game)):

- The file must be a `.zip`. CurseForge's general limit is 2 GB, and files renamed from `.rar` are rejected ([creating a project](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project)).
- No files at the zip root: `"Archive contains root level files."`
- A root folder must contain `ROOTFOLDER/ROOTFOLDER.toc`, and the name is case-sensitive: `"Archive is missing {0} (name is case sensitive and must not be empty)"`.
- The TOC must share the folder's name ([multi-TOC article](https://support.curseforge.com/support/solutions/articles/9000209856-multi-toc-for-world-of-warcraft-addons)).

The layout needed:

```text
Ergonomancer-v0.6.0.zip
└── Ergonomancer/
    ├── Ergonomancer.toc
    ├── Core.lua
    ├── ... (the other .lua files in the TOC)
    ├── LICENSE
    ├── README.md        (optional)
    └── CHANGELOG.md     (the packager generates this)
```

**macOS warning.** Finder's "Compress" adds `__MACOSX` and `.DS_Store`, which CurseForge rejects as blacklisted files ([file types, macOS section](https://support.curseforge.com/support/solutions/articles/9000197242-file-project-types-and-additional-fields)). Let the packager build the zip.

### What to exclude

- The packager never copies anything that starts with a dot (`.git`, `.github`, `.gitignore`, `.pkgmeta`, `.DS_Store`). It also skips untracked files ([release.sh `copy_directory_tree`, "Prune everything that begins with a dot"](https://github.com/BigWigsMods/packager/blob/master/release.sh)).
- Exclude these in `.pkgmeta`: `AGENTS.md`, `CLAUDE.md`, `docs/`. Listing `.github` there does nothing, but it is harmless and makes the intent clear.
- `README.md` inside the addon folder breaks no rule. Keep it or drop it. It is useful to players who unzip by hand.

### Release types

- **Release** syncs to the CurseForge app by default. A project needs at least one Release file to be available on the site and in the client.
- **Beta** syncs only for users who opt into betas.
- **Alpha** syncs only for users who opt into alphas.
- A new project needs an approved Release or Beta file to sync to the app. A project with only Alpha files appears on the website only.

Source for all four points: [CurseForge file types](https://support.curseforge.com/support/solutions/articles/9000197242-file-project-types-and-additional-fields).

The packager decides the type from the git tag ([release.sh](https://github.com/BigWigsMods/packager/blob/master/release.sh), "Automatic file type detection based on CurseForge rules"):

- An untagged commit is **alpha**.
- A tag containing "alpha" is **alpha**.
- A tag containing "beta" is **beta**, for example `v0.7.0-beta1`.
- Any other tag is **release**, for example `v0.6.0`.

### Changelog

- By default the packager writes `CHANGELOG.md` from the commit messages since the previous tag, puts it in the package, and sends it as the CurseForge, Wago and GitHub changelog ([packager README](https://github.com/BigWigsMods/packager#releasesh)).
- To use a hand-written changelog instead, set `manual-changelog` in `.pkgmeta` ([packager README](https://github.com/BigWigsMods/packager#the-packagemeta-file)).
- Commit subjects become user-facing text, so write them for players, or switch to a manual changelog.

## Game versions and flavors

### How interface numbers map to game versions

- The interface number is `major*10000 + minor*100 + patch`. The packager uses `printf "%d%02d%02d"` ([release.sh](https://github.com/BigWigsMods/packager/blob/master/release.sh)). So `120100` is 12.1.0, `120105` is 12.1.5, and `16001` is 1.60.1.
- CurseForge does not read the TOC for this. The author tags supported versions at upload, and "It is under the responsibility of the addon authors to make sure this is up to date and that the project is flagged correctly" ([multi-TOC article](https://support.curseforge.com/support/solutions/articles/9000209856-multi-toc-for-world-of-warcraft-addons)). The upload API takes `gameVersions` IDs from `/api/game/versions` ([CurseForge upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)).
- The packager reads every value on the `## Interface:` line, converts each to a version, and looks it up per flavor. It uses CurseForge `gameVersionTypeID` 517 for retail and 88568 for Forever. If CurseForge has no exact match, it uses the next lower version and prints a warning ([release.sh `upload_curseforge`](https://github.com/BigWigsMods/packager/blob/master/release.sh)). Wago and WoWInterface lookups work the same way.

### Multiple interface numbers in one TOC

- Clients since 10.2.7 (retail) and 4.4.0 accept a comma-separated `## Interface:` line. Packager v2.3.0 and later includes every value as a supported version on CurseForge, Wago and WoWInterface ([packager README](https://github.com/BigWigsMods/packager#what-changed-with-v230)).
- So one `Ergonomancer.toc` with `## Interface: 120100, 120105, 16001` is enough. No per-flavor TOC files or TOC splitting are needed.
- Whether the Forever client parses a comma list is not confirmed by Blizzard. Other addons ship `16001` inside a comma list, for example [RPGLootFeed PR #617](https://github.com/McTalian-WoW-Addons/RPGLootFeed/pull/617) (third-party).

### Forever flavor on each site

| Site | Forever listed? | Evidence |
| --- | --- | --- |
| CurseForge website | Yes, as "Forever". Files show "Forever 1.60.1". | [WoW addons version filter](https://www.curseforge.com/wow/addons), [example file tagged Forever 1.60.1](https://www.curseforge.com/wow/addons/gearquest-forever/files/8910934), [Forever search](https://www.curseforge.com/wow/search?class=addons&gameVersionTypeId=88568) |
| CurseForge app | Yes, since app 1.321 (2026-09-22): "Support for the 'Forever' beta flavor." | [CurseForge app release notes 1.321](https://blog.curseforge.com/app-release-notes-1-321/) |
| Wago Addons | Yes: flavor `forever`, patch `1.60.1`, TOC suffixes `-Camelot`, `_Camelot`, `-Forever`, `_Forever` | [Wago game data API](https://addons.wago.io/api/data/game) |
| WoWInterface | No. Game types are Retail, Classic, TBC-Classic, WOTLK-Classic, Cata-Classic. The packager skips `forever` with a warning. | [WoWInterface compatible API](https://api.wowinterface.com/addons/compatible.json), [release.sh `upload_wowinterface`](https://github.com/BigWigsMods/packager/blob/master/release.sh) |
| BigWigs packager | Yes, since v2.6.0 (2026-09-18). Interface `16???` maps to game type `forever` (alias `camelot`). | [packager PR #202](https://github.com/BigWigsMods/packager/pull/202), [release.sh](https://github.com/BigWigsMods/packager/blob/master/release.sh) |

The CurseForge support FAQ still lists only Retail, Classic and Classic Era ([WoW addons FAQ](https://support.curseforge.com/support/solutions/articles/9000198422-world-of-warcraft-addons-faq-and-troubleshooting)). That page predates Forever.

## WoW Forever

### What is known

- **Release.** Blizzard announced WoW Forever at BlizzCon 2026. The beta is live, and Blizzard's weekly post says invites go out in waves ([Blizzard news, 2026](https://news.blizzard.com/en-us/article/24304074/blizzcon-2026-wow-forever-beta-midnight-s3-and-more-in-this-weeks-wow-weekly)). The November 4 launch date comes from press coverage, not a Blizzard page fetched here.
- **Client version.** 1.60.1. Blizzard's extracted UI source for the Forever branch is committed as `1.60.1 (69977)` and earlier builds ([Gethe/wow-ui-source `forever` branch](https://github.com/Gethe/wow-ui-source/commits/forever)). The build list shows product `wow_classic_beta` at `1.60.1.69977` ([wago.tools builds API](https://wago.tools/api/builds)). The Gethe repo mirrors Blizzard's files but is run by a third party. wago.tools is a third-party build tracker that reads Blizzard's CDN.
- **Game type is `camelot`, not `wowhack`.** In the Forever branch, Blizzard's own TOC loads Forever overrides with `[AllowLoadGameType camelot]`. `wowhack` appears paired with `plunderstorm`, the arcade mode: `[Game]\EditModePresetLayouts.lua [AllowLoadGameType wowhack, plunderstorm]` ([Blizzard_EditMode.toc, forever branch](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Blizzard_EditMode.toc)). The UI has Mainline code plus `Camelot/` override folders.
- **The APIs Ergonomancer uses exist in Forever.** The Forever branch's generated API docs include `C_Minimap.IsInsideQuestBlob`, `C_Minimap.GetViewRadius`, `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED`, `C_QuestLog.GetDistanceSqToQuest` and `C_QuestLog.GetQuestsOnMap` (checked in `Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua` and `QuestLogDocumentation.lua` on the [forever branch](https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated)).
- **Why the owner thought it was 12.1.5.** A Blizzard representative said in the WoW UI Discord that "WoW Forever shares Mainline WoW's UI architecture, including the vast majority of APIs available in 12.1.5." That is the API set, not the client version or interface number. This is second-hand: [Icy Veins](https://www.icy-veins.com/wow-forever/news/addons-in-wow-forever-blizzard-devs-just-addressed-the-big-question/) reports it. The Discord message itself could not be read.
- **Interface number.** `16001` follows from version 1.60.1 and Blizzard's `%d%02d%02d` format. The packager treats `16???` as Forever ([release.sh](https://github.com/BigWigsMods/packager/blob/master/release.sh)).
- **How players install addons.** They can use the CurseForge app (Forever flavor, app 1.321 or later) or install by hand. For a manual install, the folder goes into the Forever client's `Interface/AddOns`. The install folder appears to be `_classic_beta_`, which matches the `wow_classic_beta` product. That comes only from a player's forum post, which mentions `_classic_beta_\WTF\Account\SavedVariables\` ([Blizzard EU forums](https://eu.forums.blizzard.com/en/wow/t/wow-forever-game-not-save-any-addons-settings/629470)).
- **Known beta issue relevant to Ergonomancer.** The same player thread reports that SavedVariables do not load after a cold client start in the Forever beta, so settings reset. There is no Blizzard reply. Ergonomancer stores settings in `ErgonomancerDB`, so its settings and `/ergo debug` state may reset in the beta until Blizzard fixes this.

### What is not known

- There is no Blizzard documentation of Forever's interface number, TOC suffixes or install path. Everything above comes from the client files, build trackers, tool source code and site metadata.
- Unconfirmed: whether the Forever client loads an addon whose TOC lists only `120100, 120105`, and whether it marks such an addon "Out of date". Retail treats an addon as out of date when its interface is older than the client's ([Warcraft Wiki, TOC format](https://warcraft.wiki.gg/wiki/TOC_format), community source). How a newer-than-client number is treated was not found in any source. The README says Ergonomancer started from Forever's gamepad mode, so it apparently loads there. The `/dump` check in step 1 of the checklist settles this.
- Unconfirmed: which TOC suffixes the Forever client reads. Wago lists `_Camelot` and `_Forever`. The community wiki says `_Camelot.toc` and `_Mainline.toc` both load in Forever ([Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format)). Blizzard's own Forever branch ships `Blizzard_WorldMap_Mainline.toc`, which suggests `_Mainline` is read. Ergonomancer uses a plain `Ergonomancer.toc`, so this matters only if per-flavor TOCs are needed later.
- Whether `16001` will change. A packager maintainer asked to hold off on Forever TOC detection "until we have solid confirmation" ([packager PR #202](https://github.com/BigWigsMods/packager/pull/202)). The mapping still ships in v2.6.1, and it covers `16000` to `16999`.

### What it means for Ergonomancer

- Add `16001` to `## Interface:` once the in-game check confirms it. The next tagged release will then be tagged "Forever 1.60.1" on CurseForge and Wago, and Forever players can find it in the CurseForge app.
- Without `16001`, uploads are tagged Retail only. Forever players would not see Ergonomancer in the app's Forever flavor and would have to install it by hand.

## Automated releases with the BigWigs packager

### How it works

- `BigWigsMods/packager@v2` runs `release.sh`. It copies the checkout into `.release/Ergonomancer/`, applies `.pkgmeta`, zips the result, and uploads it to CurseForge, WoWInterface, Wago and GitHub releases ([packager README](https://github.com/BigWigsMods/packager#releasesh)).
- The package name comes from the TOC file name, so the folder is `Ergonomancer` whatever the repo is called ([release.sh](https://github.com/BigWigsMods/packager/blob/master/release.sh)). `package-as` makes that explicit.
- The version comes from the git tag. The changelog covers commits since the previous tag, so the checkout needs full history (`fetch-depth: 0`) ([packager wiki](https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow)).
- `release.sh` uses `git describe --tags`, so lightweight tags work. The wiki still says "make sure your tags are annotated!", so use `git tag -a`.
- The TOC's `## Version: 0.6.0` is hard-coded. Either keep the tag equal to it (`v0.6.0` with `0.6.0`), or change the line to `## Version: @project-version@`, which the packager replaces with the tag ([packager README, string replacements](https://github.com/BigWigsMods/packager#string-replacements)). The second option means a local symlinked checkout shows the literal `@project-version@` in-game.

### TOC fields

| Field | Where the value comes from | Source |
| --- | --- | --- |
| `## X-Curse-Project-ID: 1234` | "About Project" box on the CurseForge project page | [packager README](https://github.com/BigWigsMods/packager#customizing-the-build) |
| `## X-Wago-ID: he54k6bL` | Wago developer dashboard, under the addon name (8 characters) | [packager README](https://github.com/BigWigsMods/packager#customizing-the-build), [Wago API docs](https://docs.wago.io/) |
| `## X-WoWI-ID: 5678` | The number in the WoWInterface URL, for example `info5678-MyAddon` | [packager README](https://github.com/BigWigsMods/packager#customizing-the-build) |

If a field is missing, the packager skips that site. CurseForge needs the ID and a token. Wago needs the ID and a token. WoWInterface needs the ID, a token and a tag ([release.sh upload functions](https://github.com/BigWigsMods/packager/blob/master/release.sh)).

### Secrets and token names

The names changed in June 2026 ([packager commit 36b4c3b](https://github.com/BigWigsMods/packager/commit/36b4c3b7)). `release.sh` accepts both old and new names ([release.sh lines 494 to 499](https://github.com/BigWigsMods/packager/blob/master/release.sh)):

| Purpose | Current name | Old name, still accepted | Where to create it |
| --- | --- | --- | --- |
| CurseForge | `CF_API_TOKEN` | `CF_API_KEY` | <https://authors.curseforge.com/#/settings/api-tokens> ([packager README](https://github.com/BigWigsMods/packager#uploading)). CurseForge's own article links <https://authors-old.curseforge.com/account/api-tokens> ([CurseForge upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)). |
| Wago | `WAGO_API_TOKEN` | none | <https://addons.wago.io/account/apikeys> |
| WoWInterface | `WOWI_API_TOKEN` | none | <https://www.wowinterface.com/downloads/filecpl.php?action=apitokens> |
| GitHub release | `GITHUB_API_TOKEN` | `GITHUB_OAUTH` | Use the built-in `secrets.GITHUB_TOKEN` with `contents: write`. No personal token is needed ([packager wiki](https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow)). |

Store each token under Settings > Secrets and variables > Actions in the GitHub repo. The CurseForge token is sent in the `X-Api-Token` header ([CurseForge upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)).

### Example `.pkgmeta`

```yaml
package-as: Ergonomancer

ignore:
  - AGENTS.md
  - CLAUDE.md
  - docs
  - .github
```

`docs` matches the whole directory, because the packager turns an existing directory into a `docs/*` pattern ([release.sh `parse_ignore`](https://github.com/BigWigsMods/packager/blob/master/release.sh)). `.github` is already skipped as a dotfile, so that line is only documentation.

### Example workflow `.github/workflows/release.yml`

```yaml
name: Package and release

on:
  push:
    tags:
      - "**"

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    env:
      CF_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
      WAGO_API_TOKEN: ${{ secrets.WAGO_API_TOKEN }}
      WOWI_API_TOKEN: ${{ secrets.WOWI_API_TOKEN }}
      GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: BigWigsMods/packager@v2
```

Based on the [packager wiki workflow](https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow), with the current secret names. `actions/checkout` v7.0.1 is the latest release ([actions/checkout releases](https://github.com/actions/checkout/releases)). If a secret is not set, that site's upload is skipped. You can create only the secrets you need.

### Release flow

```bash
git tag -a v0.6.0 -m "Ergonomancer 0.6.0"
git push origin v0.6.0
```

For a beta, use a tag such as `v0.7.0-beta1`.

### Bootstrapping the first CurseForge file

CurseForge needs a file before moderation starts, and the packager needs the project ID. Order:

1. Create the project.
2. Add `X-Curse-Project-ID`.
3. Push the first tag.

Unconfirmed: whether the upload API accepts a file for a project still in "New" status. If the upload fails, download the zip from the GitHub release the same run created and upload it by hand in the CurseForge Files tab.

## Wago Addons

- **Account.** Sign-in is only via Battle.net or GitHub (observed on <https://addons.wago.io/developers>). The Developer Agreement requires the account to be "connected to a verified Blizzard Entertainment account or GitHub account" and the developer to be 18 or older ([Wago Developer Agreement](https://addons.wago.io/agreements/developer-agreement)).
- **Project.** Create it in the developer dashboard. The 8-character project ID is printed under the addon name ([Wago API docs](https://docs.wago.io/)). The agreement says you must tell Wago in writing what the addon does before submitting ([Developer Agreement](https://addons.wago.io/agreements/developer-agreement)). In practice that is probably the project description field, but this is unconfirmed.
- **Uploads.** The docs recommend the BigWigs packager with `WAGO_API_TOKEN`. The manual API is `POST https://addons.wago.io/api/projects/<id>/version` ([Wago API docs](https://docs.wago.io/)). The packager maps "release" to Wago's "stable" ([release.sh `upload_wago`](https://github.com/BigWigsMods/packager/blob/master/release.sh)).
- **Rules that differ from CurseForge:**
  - The download must be a zip with no `.exe`.
  - The addon must not collect personal information.
  - No advertising or brand promotion in the addon or on the landing page, "including but not limited to advertising in its name, its content, its functionality". This is stricter than CurseForge, which allows donation links at the bottom.
  - Wago may stop hosting any addon with 7 days' notice.
  - Revenue share is opt-in: 70% of an ad revenue pool split by downloads, 85% of subscriptions, paid in Wago Credits and redeemable above $50.

  Source for all five: [Wago Developer Agreement](https://addons.wago.io/agreements/developer-agreement).
- **Forever.** Supported: `forever` flavor, patch `1.60.1` ([Wago game data API](https://addons.wago.io/api/data/game)). Retail `12.1.5` is also listed.
- **Review.** No public statement on whether Wago reviews new projects, or how long review takes. Unconfirmed.
- **Worth doing now?** Yes, if CurseForge automation is set up anyway. It adds one TOC line and one secret.

## WoWInterface

- **Account and upload.** Create a site account, then upload through the site. Submissions go to a moderation queue, and "We may or may not contact you if we decline your submission". Updates to files go back to the queue for security review. Description edits are immediate. The FAQ also sets a 6 MB limit, no executables and no nested zips, and asks for a screenshot ([WoWInterface FAQ: uploading and managing](https://www.wowinterface.com/forums/faq.php?faq=managing)). The FAQ is old, so treat details like the screenshot format as possibly outdated.
- **ID.** The addon ID appears in the URL after the first upload is created ([packager README](https://github.com/BigWigsMods/packager#customizing-the-build)). The first upload has to be manual.
- **Token.** Create it at <https://www.wowinterface.com/downloads/filecpl.php?action=apitokens> ([packager README](https://github.com/BigWigsMods/packager#uploading)).
- **Versions.** Game types are Retail and four Classic types. The newest retail entry is 12.1.0, and there is no Forever ([WoWInterface compatible API](https://api.wowinterface.com/addons/compatible.json)). The packager maps 12.1.5 down to 12.1.0 and skips `forever` with a warning ([release.sh `upload_wowinterface`](https://github.com/BigWigsMods/packager/blob/master/release.sh)).
- **Changelog.** The packager converts the Markdown changelog to BBCode for WoWInterface if pandoc is present ([packager README](https://github.com/BigWigsMods/packager#the-packagemeta-file)).
- **Worth doing now?** Low value for a Forever-first addon. It is safe to add later. The only cost is one manual first upload.

## GitHub

- **Public repo.** Not required by the packager. Actions and uploads work from a private repo. A public repo is still the better choice:
  - Blizzard's policy wants code "freely accessible to and viewable by the general public" ([Blizzard policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534)). The zip already satisfies this, but a public repo is clearer.
  - CurseForge strongly recommends a channel for bug reports ([moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)). GitHub issues provides one.
  - The CurseForge app, Wago and addon managers can link to the source.
- **Tags.** Required for release and beta builds. Untagged runs produce alpha builds. GitHub and WoWInterface uploads happen only for tagged builds ([release.sh](https://github.com/BigWigsMods/packager/blob/master/release.sh)). The example workflow runs only on tags, so every run is a release or beta.
- **Releases.** The packager creates or updates a GitHub release named after the tag. Non-release tags are marked as prereleases. It attaches the zip and a `release.json` that lists each flavor and interface, for example `{"flavor":"forever","interface":16001}` ([release.sh `upload_github`](https://github.com/BigWigsMods/packager/blob/master/release.sh)). Addon managers that install from GitHub read that file.
- **Permissions.** `GITHUB_TOKEN` needs write access to contents, or the job fails with "Resource not accessible by integration" ([packager wiki](https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow)).
- **Checkout depth.** Use `fetch-depth: 0` so the changelog can find the previous tag.

## Unconfirmed items

1. **Forever interface number.** `16001` is inferred from client version 1.60.1 and from tool source code. Blizzard has not documented it. Tried: Blizzard news and forums (no blue post on interface numbers) and Blizzard's extracted Forever UI source (its only TOC `## Interface:` line is `0`). The in-game `/dump` check settles it.
2. **Whether Forever loads a TOC listing only `120100, 120105`, and whether it shows "Out of date".** Not found in any source.
3. **Whether the Forever client parses a comma-separated `## Interface:` line.** Other addons do this, but Blizzard has not documented it.
4. **Forever install folder `_classic_beta_`.** Only from a player forum post, consistent with the `wow_classic_beta` product on wago.tools. Brian can check his own install.
5. **Blizzard's "12.1.5 APIs" statement.** Known only through Icy Veins. The original was a WoW UI Discord message, which could not be read.
6. **CurseForge policy on AI-generated code.** Only a rule on AI showcase images was found. Checked: moderation policies, submission guide, Mod Authors Terms.
7. **CurseForge policy on obfuscation.** Not in CurseForge's pages. Blizzard's policy forbids it, and CurseForge requires projects to follow the game's ToS.
8. **Whether the CurseForge upload API accepts a first file for a project in "New" status.** Not documented. The manual upload fallback is described above.
9. **Whether CurseForge already lists game version 12.1.5.** Its versions API needs a token, so this could not be checked. The packager falls back to 12.1.0 with a warning if 12.1.5 is missing.
10. **Wago review process and timing.** Not documented publicly. The developer dashboard needs sign-in.
11. **Avatar or screenshot size rules for Wago and WoWInterface.** Not found in their public pages.
12. **WoW Forever launch date (November 4, 2026).** From press coverage ([Game Informer](https://gameinformer.com/blizzcon-2026/2026/09/12/blizzard-announces-world-of-warcraft-forever-expanding-vanilla-wow-with)). The Blizzard weekly post fetched here does not state it.
