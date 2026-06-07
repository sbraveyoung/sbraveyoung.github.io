# Auth: PAT → GitHub App migration

The deploy pipeline currently authenticates as `GH_PAT` — a fine-grained
Personal Access Token tied to one user account. Simple, but three
problems lurk:

1. **Single point of failure.** PAT expires, gets revoked, or owner's
   account is suspended — every deploy stops silently.
2. **No per-repo audit trail.** Every Action run authenticates as the
   token owner; there's no "this run was the deploy bot" distinction.
3. **Token permissions are a union.** A fine-grained PAT with
   `Contents: Write` on N repos can write to any of those N. A GitHub
   App's installation token is scoped per installation.

When the PAT starts pulling its weight, switch to a **GitHub App** with
installation tokens. Steps below.

## Steps

1. **Create the App** at https://github.com/settings/apps/new.
   - Name: `gobog-deploy` (or anything unique).
   - Homepage URL: anything (e.g. https://sbrave.cn).
   - Webhook: uncheck "Active".
   - Repository permissions:
     - **Contents: Read and write**
     - **Metadata: Read** (mandatory)
   - Where can this App be installed: "Only on this account".

2. **Install** the App on the three repos it needs to act on:
   - `sbraveyoung/blog`
   - `sbraveyoung/sbraveyoung.github.io`
   - `sbraveyoung/gobog`

3. **Generate a private key** on the App's settings page; download the
   `.pem`.

4. **Add two repository secrets** to *both* `sbraveyoung/blog` and
   `sbraveyoung/sbraveyoung.github.io`:

   | Name             | Value                                  |
   | ---------------- | -------------------------------------- |
   | `GOBOG_APP_ID`   | numeric App ID                         |
   | `GOBOG_APP_PEM`  | entire `.pem` file contents (newlines intact) |

5. **Update the workflows** to mint an installation token instead of
   reading `GH_PAT`. In `sbraveyoung/blog/.github/workflows/deploy.yml`
   replace the existing `Dispatch deploy event` step's auth header:

   ```yaml
   - name: Mint installation token
     id: app-token
     uses: actions/create-github-app-token@v1
     with:
       app-id: ${{ secrets.GOBOG_APP_ID }}
       private-key: ${{ secrets.GOBOG_APP_PEM }}
       owner: sbraveyoung
       repositories: sbraveyoung.github.io

   - name: Dispatch deploy event
     env:
       TOKEN: ${{ steps.app-token.outputs.token }}
     run: |
       curl -sSf -X POST \
         -H "Accept: application/vnd.github+json" \
         -H "Authorization: Bearer $TOKEN" \
         -H "X-GitHub-Api-Version: 2022-11-28" \
         https://api.github.com/repos/sbraveyoung/sbraveyoung.github.io/dispatches \
         -d '{"event_type":"blog-update","client_payload":{"sha":"${{ github.sha }}","ref":"${{ github.ref }}"}}'
   ```

   In `sbraveyoung/sbraveyoung.github.io/.github/workflows/deploy.yml`
   do the same at the top of the job and swap every
   `${{ secrets.GH_PAT || secrets.GITHUB_TOKEN }}` for
   `${{ steps.app-token.outputs.token }}`. The token expires after 1h
   — the deploy runs much faster than that, so no renewal needed.

6. **Revoke the old PAT** at https://github.com/settings/tokens once
   the App is verified working through a successful run.

## Why we haven't done this yet

PATs are simpler and there's one author. The migration is worth doing
when any of these become true:

- You start having AI-coding agents commit on your behalf (bot identity
  becomes worth distinguishing).
- You want per-repo audit logs for compliance reasons.
- You don't want deploys to break the day you take a sabbatical from
  GitHub.
