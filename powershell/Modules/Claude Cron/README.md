# ClaudeCron

Queue Claude prompts and shell commands, then run them at a fixed time, on a repeating
interval, or as soon as your AI quota comes back.

The problem it solves: you run out of quota at 11pm with three things you still wanted
Claude to do. Queue them, go to bed, and the worker sends them the moment the window
resets — as long as the machine is still awake, which is what the
[Keeping Linux Mint awake](#keeping-linux-mint-awake) section is about.

---

## Table of contents

- [Install](#install)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Command reference](#command-reference)
- [Configuration](#configuration)
- [Quota handling](#quota-handling)
- [When the CLI is signed out](#when-the-cli-is-signed-out)
- [Scheduling on Linux](#scheduling-on-linux)
  - [Option A: crontab](#option-a-crontab)
  - [Option B: systemd user timer (recommended)](#option-b-systemd-user-timer-recommended)
  - [Option C: a worker you leave running](#option-c-a-worker-you-leave-running)
  - [Writing cron expressions](#writing-cron-expressions)
  - [Debugging a cron job that will not run](#debugging-a-cron-job-that-will-not-run)
- [Keeping Linux Mint awake](#keeping-linux-mint-awake)
- [Files on disk](#files-on-disk)
- [Tests](#tests)

---

## Install

Symlink the module into your PowerShell modules folder so it auto-loads and stays in
sync with this config repo:

```bash
ln -s "/home/nwb/.var/app/dev.neovide.neovide/config/nvim/powershell/Modules/ClaudeCron" "$HOME/.local/share/powershell/Modules/ClaudeCron"
```

Then confirm PowerShell can see it:

```bash
pwsh -NoProfile -c 'Import-Module ClaudeCron; Get-Command -Module ClaudeCron'
```

Requirements: PowerShell 7.2+, and the `claude` CLI on your `PATH` for prompt jobs.
Command jobs work without it.

Tell the module where the CLI lives — use the absolute path, because a scheduled run has
a much shorter `PATH` than your login shell:

```bash
pwsh -NoProfile -c 'Import-Module ClaudeCron; Set-ClaudeCronConfig -ClaudeCommand /home/nwb/.local/bin/claude'
```

Point it at the `~/.local/bin/claude` symlink rather than the versioned binary it
resolves to, so a CLI update does not leave the config pointing at a version that is no
longer there.

Sign in once before queueing anything — a scheduled run cannot complete a login prompt:

```bash
claude
```

## Quick start

```powershell
Import-Module ClaudeCron

# Queue work for whenever quota is next available.
Add-ClaudeCronPrompt 'Add Pester tests for QDtb.SvgToReact' -Name svg-tests -WorkingDirectory ~/src/qdtb

# Run something at a specific time tonight.
Add-ClaudeCronPrompt 'Write release notes from the last 20 commits' -At '23:30'

# Repeat on an interval, or on a cron expression.
Add-ClaudeCronPrompt 'Triage new GitHub issues' -Cron '0 8 * * 1-5'
Add-ClaudeCronCommand 'git -C ~/src/qdtb pull --ff-only' -Every 1h

# See what is queued, and what the queue is waiting on.
Get-ClaudeCronJob | Format-Table Id, Name, Status, RunAfter, RunCount
Get-ClaudeCronStatus

# Drain it by hand right now.
Invoke-ClaudeCronQueue

# Read what a job actually produced.
Get-ClaudeCronLog svg-tests -Tail 40
```

Three aliases exist for the commands you type most: `ccadd` (`Add-ClaudeCronPrompt`),
`ccq` (`Get-ClaudeCronJob`) and `ccrun` (`Invoke-ClaudeCronQueue`).

## How it works

Each queued item is a JSON file under `~/.config/claude-cron/queue/`. Nothing runs on a
timer inside the module itself — a scheduler (cron, a systemd timer, or the built-in
worker loop) calls `Invoke-ClaudeCronQueue`, and that one call does all the work:

1. If the queue is paused waiting for a quota reset, and the reset has not happened yet,
   it returns immediately.
2. Otherwise it collects every job whose `RunAfter` has passed, ordered by `Priority`
   then age, and runs them **one at a time**.
3. A prompt job runs `claude --print --permission-mode acceptEdits <prompt>` in the
   job's working directory. Everything it prints, on both stdout and stderr, is appended
   to that job's log file.
4. Exit code 0 → the job is `Done`, or rescheduled if it repeats.
   Any other exit → the attempt counter goes up, the job is pushed back a few minutes,
   and after `MaxAttempts` it becomes `Failed`.
   Quota exhaustion → see below; it does not count as an attempt.

A lock file stops two drains from overlapping, so it is safe to have cron firing every
ten minutes while a long job is still running: the second drain notices the lock, logs
that it is skipping, and exits.

## Command reference

| Command | What it does |
| --- | --- |
| `Add-ClaudeCronPrompt` | Queue a Claude prompt. `-At`, `-Every`, `-Cron`, `-Model`, `-WorkingDirectory`, `-Priority`, `-MaxRuns`, `-ClaudeArgs` |
| `Add-ClaudeCronCommand` | Queue a shell/PowerShell command. Same scheduling switches, plus `-Shell pwsh\|sh` |
| `Get-ClaudeCronJob` | List jobs. Filter with a name/id, `-Status`, or `-Due` |
| `Set-ClaudeCronJob` | Change a job in place: reschedule, re-prioritise, `-Enable`, `-Disable` |
| `Remove-ClaudeCronJob` | Delete a job and its log |
| `Clear-ClaudeCronQueue` | Drop finished jobs (default `Done` + `Failed`), or `-All` |
| `Get-ClaudeCronLog` | Show a job's captured output, or the module log with no argument. `-Tail`, `-Wait` |
| `Invoke-ClaudeCronQueue` | Run everything that is due. `-Limit`, `-Identity`, `-Force` |
| `Start-ClaudeCronWorker` | Poll the queue in the foreground until Ctrl+C |
| `Get-ClaudeCronStatus` | Counts by state, quota block, next run, installed schedulers |
| `Get-ClaudeCronQuota` / `Set-ClaudeCronQuota` / `Clear-ClaudeCronQuota` | Inspect, set or lift the quota pause |
| `Get-ClaudeCronConfig` / `Set-ClaudeCronConfig` | Read and write settings |
| `Install-ClaudeCronSchedule` / `Uninstall-ClaudeCronSchedule` | Manage the crontab entry |
| `Install-ClaudeCronTimer` / `Uninstall-ClaudeCronTimer` | Manage the systemd user timer |
| `Get-ClaudeCronSchedule` | Report which schedulers are installed |
| `Get-ClaudeCronDrainCommand` | The exact command line a scheduler should run |

Every command has comment-based help: `Get-Help Add-ClaudeCronPrompt -Full`.

Anything that changes state supports `-WhatIf`, including both installers — use it to
see the crontab or unit file that would be written before writing it.

## Configuration

`Set-ClaudeCronConfig` writes `~/.config/claude-cron/config.json`.

| Setting | Default | Notes |
| --- | --- | --- |
| `ClaudeCommand` | `claude` | Set this to an absolute path for scheduled runs |
| `DefaultClaudeArgs` | `--print --permission-mode acceptEdits` | What makes an unattended run possible |
| `DefaultModel` | *(empty)* | Passed as `--model` when set |
| `DefaultWorkingDirectory` | `$HOME` | Per-job `-WorkingDirectory` overrides it |
| `PollSeconds` | `300` | How often `Start-ClaudeCronWorker` drains |
| `QuotaResetHours` | `5` | Fallback pause when the CLI reports no reset time |
| `MaxAttempts` | `3` | Retries before a job is marked `Failed` |
| `JobTimeoutMinutes` | `60` | Longer runs are killed and recorded as exit 124 |
| `NotifyCommand` | *(empty)* | e.g. `notify-send "{title}" "{message}"` |

Set `CLAUDE_CRON_HOME` to move the whole data directory somewhere else — the test suite
uses this to stay out of your real queue.

A note on `-ClaudeArgs`: `--permission-mode acceptEdits` lets Claude edit files without
asking, which is the point of an unattended queue. `--dangerously-skip-permissions` goes
further and also allows shell commands; only reach for it on jobs whose working
directory you are willing to let a script rewrite unattended.

## Quota handling

This is the feature the module exists for.

When a prompt job fails and its output looks like a quota or rate limit, the runner:

- puts the job **straight back on the queue** as `Pending`, without spending one of its
  retry attempts;
- pauses the whole queue until the reset time;
- abandons the rest of that drain, so twenty queued prompts do not each burn a failed
  call against a limit that is already gone.

The reset time comes from the CLI's machine readable sentinel
(`Claude AI usage limit reached|<unix seconds>`) when present. Failing that, a wall clock
time in the message ("resets at 6pm") is used. Failing both, `QuotaResetHours` is added
to now.

Every drain after that returns immediately until the reset passes; the first drain after
it logs `Quota window has reset; resuming the queue` and works through the backlog.
`Start-ClaudeCronWorker` goes further and sleeps until a minute past the reset rather
than waking up every five minutes to do nothing.

You can drive the pause yourself. If you hit the limit in an interactive session and
want the queue to respect it too:

```powershell
Set-ClaudeCronQuota -In 5h            # or: -Until '18:00'
Get-ClaudeCronQuota                   # Blocked, BlockedUntil, Remaining
Clear-ClaudeCronQuota                 # changed your mind
Invoke-ClaudeCronQueue -Force         # ignore the pause for one drain
```

Only prompt jobs can trigger the pause. A command job that exits non-zero is just a
failed command, even if its output mentions a rate limit.

## When the CLI is signed out

An expired login looks like a failure on every job, but it is not transient and it is not
a quota window: nothing will succeed until a human signs in. So the runner treats it
much like a quota block — the job keeps its full retry budget and the drain stops after
the first one, rather than marching through the whole queue turning it into `Failed`.

The difference is that no pause is set, because there is no reset time to wait for. The
next drain simply tries again, which picks the queue back up on its own once you have
logged in.

You will see this in the log:

```
[WARN ] The Claude CLI is not signed in (Failed to authenticate). Run 'claude' to log in; the queue is untouched and will retry.
[WARN ] Stopping this drain: the Claude CLI is signed out.
```

The fix is to run `claude` in a terminal and sign in. Nothing else is needed — the queue
was never damaged.

---

## Scheduling on Linux

Pick one of the three. Do not run both cron and the systemd timer — they would fight
over the lock and log a lot of "another worker holds the lock".

### Option A: crontab

The module writes and removes its own crontab block, so you never have to hand-edit:

```powershell
Install-ClaudeCronSchedule -Cron '*/10 * * * *' -WhatIf   # preview
Install-ClaudeCronSchedule -Cron '*/10 * * * *'           # do it
Get-ClaudeCronSchedule                                     # confirm
Uninstall-ClaudeCronSchedule                               # remove it
```

It only ever touches the lines between its own markers:

```
# >>> claude-cron >>>
SHELL=/bin/sh
HOME=/home/nwb
PATH=...
*/10 * * * * /path/to/pwsh -NoProfile -NonInteractive -Command "Import-Module '...' -Force; Invoke-ClaudeCronQueue" >> ~/.config/claude-cron/logs/cron.log 2>&1
# <<< claude-cron <<<
```

Everything else in your crontab is preserved byte for byte.

**Doing it by hand instead.** `crontab -e` opens your personal crontab (`crontab -l`
lists it; `crontab -r` deletes the whole thing without asking, so avoid it). If the
editor is not one you want, set it for that command: `EDITOR=nano crontab -e`. Get the
command line to paste from `(Get-ClaudeCronDrainCommand).CommandLine`.

Things that bite people writing crontabs by hand:

- **The environment is nearly empty.** Cron does not read `~/.bashrc`, `~/.profile`, or
  your fish config. `PATH` is typically just `/usr/bin:/bin`. Use absolute paths for
  everything, or set `PATH=` at the top of the crontab as the installer does.
- **`%` is special.** In a crontab, an unescaped `%` becomes a newline and everything
  after the first one is fed to the command as stdin. Write `\%` if you need a literal
  one. (This module keeps prompts in JSON files, never in the crontab, so it is not a
  problem here.)
- **Every line must end in a newline**, including the last one.
- **Nothing is logged by default.** Cron mails output to the local user, which on a
  desktop nobody reads. Always redirect: `>> /path/to/log 2>&1`. Set `MAILTO=""` at the
  top of the crontab to silence the mail attempt entirely.
- **`~` does not expand** in the schedule fields' command in all cron implementations —
  spell out `/home/you/...`.
- **Cron uses the system timezone.** Check it with `timedatectl`. A cron line does not
  move when daylight saving does: jobs scheduled in the hour that repeats run twice, and
  jobs in the hour that vanishes do not run at all. `*/10` schedules do not care.
- **Cron does not catch up.** If the machine was asleep or off at 03:00, the 03:00 job
  simply did not happen. This is the single biggest reason to prefer Option B.

Is cron even installed? Linux Mint ships it, but a minimal install may not:

```bash
systemctl status cron
```

```bash
sudo apt install cron && sudo systemctl enable --now cron
```

### Option B: systemd user timer (recommended)

Better than cron on a laptop, for one reason: `Persistent=true`. If the timer's window
was missed because the machine was asleep or powered off, systemd fires it as soon as
the machine comes back, instead of skipping it. That is exactly the behaviour you want
for "run my queue when quota resets" on a machine that suspends overnight.

```powershell
Install-ClaudeCronTimer -OnCalendar '*:0/10'   # every 10 minutes
Get-ClaudeCronSchedule
Uninstall-ClaudeCronTimer
```

That writes `~/.config/systemd/user/claude-cron.service` and `claude-cron.timer`, then
enables and starts the timer. Useful checks:

```bash
systemctl --user list-timers claude-cron.timer
```

```bash
systemctl --user status claude-cron.service
```

```bash
journalctl --user -u claude-cron.service -n 50 --no-pager
```

`OnCalendar` is systemd's own syntax, not cron's. Common forms: `*:0/10` (every ten
minutes), `hourly`, `daily`, `Mon..Fri 08:00`, `*-*-* 03:30:00`. Check one before you
install it:

```bash
systemd-analyze calendar 'Mon..Fri 08:00'
```

**User services stop when you log out.** Enable lingering so the timer keeps running
across logout and from boot:

```bash
loginctl enable-linger $USER
```

### Option C: a worker you leave running

No scheduler at all — a loop in a terminal, which is the easiest thing to watch while
you are setting up:

```powershell
Start-ClaudeCronWorker -PollSeconds 120
```

It drains, sleeps, repeats, and while a quota pause is in force it sleeps straight
through to the reset. Ctrl+C stops it. Good for a session you are supervising; use
Option A or B for anything you expect to survive a reboot.

### Writing cron expressions

The `-Cron` parameter on a job and the `-Cron` parameter on `Install-ClaudeCronSchedule`
both take standard five-field expressions, parsed by this module:

```
┌───────────── minute (0-59)
│ ┌─────────── hour (0-23)
│ │ ┌───────── day of month (1-31)
│ │ │ ┌─────── month (1-12 or jan-dec)
│ │ │ │ ┌───── day of week (0-7 or sun-sat; 0 and 7 are both Sunday)
│ │ │ │ │
* * * * *
```

`*` any value · `5` exactly 5 · `1-5` a range · `1,15,30` a list · `*/10` every tenth ·
`8-18/2` every second value in a range. The macros `@hourly`, `@daily`, `@midnight`,
`@weekly`, `@monthly` and `@yearly` also work.

| Expression | Meaning |
| --- | --- |
| `*/10 * * * *` | every 10 minutes |
| `0 * * * *` | on the hour |
| `0 8 * * 1-5` | 08:00 on weekdays |
| `30 6,18 * * *` | 06:30 and 18:30 |
| `0 3 1 * *` | 03:00 on the 1st of each month |
| `0 0 * * 0` | midnight on Sunday |

As in standard cron, when *both* day-of-month and day-of-week are restricted, a day
matching **either** one is a match.

To check what an expression will do without queueing anything:

```powershell
& (Get-Module ClaudeCron) { Get-ClaudeCronNextRun -Expression '0 8 * * 1-5' }
```

### Debugging a cron job that will not run

Work down this list; it is almost always one of the first three.

1. **Is cron running at all?** `systemctl status cron`
2. **Did cron try?** `journalctl -u cron --since '1 hour ago' --no-pager` — you will see
   a `CMD (...)` line for every attempt. A line there plus nothing in your log means the
   command ran and failed early.
3. **What did it say?** `Get-ClaudeCronLog` with no argument for the module log, or
   `cat ~/.config/claude-cron/logs/cron.log` for whatever the command printed before the
   module got involved. `pwsh: command not found` in there means the crontab `PATH` is
   wrong.
4. **Does the command work outside cron?** Run
   `(Get-ClaudeCronDrainCommand).CommandLine` in a terminal, verbatim.
5. **Reproduce cron's empty environment**: `env -i HOME=$HOME /bin/sh -c '<command>'`.
   If it fails here but works in your shell, something in your profile is doing work
   that cron does not do — usually `PATH`.
6. **Is the queue paused?** `Get-ClaudeCronStatus` — a quota block makes a perfectly
   healthy drain look like it does nothing.
7. **Is a stale lock in the way?** The log says "another worker holds the lock" every
   drain. Check `cat ~/.config/claude-cron/worker.lock` and whether that pid still
   exists; the module clears locks it can prove are stale on its own.
8. **Was the machine asleep?** `journalctl -b -u systemd-suspend` or
   `last -x | head` shows suspends and reboots. If so, the next section is the fix.

---

## Keeping Linux Mint awake

A queued job cannot run on a suspended machine. Cron does not catch up afterwards; a
systemd timer with `Persistent=true` does, but only once the machine wakes. If you want
prompts to go out at 04:00 when the quota resets, the machine has to be awake at 04:00.

Mint's defaults suspend an idle desktop after some period on AC power, so check this
before trusting an overnight queue.

### The GUI way (Cinnamon)

**Menu → System Settings → Power Management**

- *On AC power* → **Turn off the screen when inactive for**: your preference, this is
  only the display.
- *On AC power* → **Suspend when inactive for**: **Never**. This is the one that matters.
- Set the same under *On battery* if the machine runs on battery overnight.
- **When the lid is closed**: **Do nothing** on a laptop that lives on a desk.

**Menu → System Settings → Screensaver** → turn off *Lock the computer when put to
sleep* if a locked session gets in your way; locking itself does not stop cron.

MATE and Xfce editions have the same settings under **Power Management**; the wording is
close enough to follow.

### The command line way

Cinnamon stores those settings in dconf, so you can set them from a script:

```bash
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
```

```bash
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
```

```bash
gsettings set org.cinnamon.settings-daemon.plugins.power lid-close-ac-action 'nothing'
```

`0` means never. Read a value back with `gsettings get <schema> <key>`. On MATE the
schema is `org.mate.power-manager` (`sleep-computer-ac`); on Xfce use
`xfconf-query -c xfce4-power-manager -l -v`.

Stop the screen blanking too, on an X11 session:

```bash
xset s off -dpms
```

### Just for the duration of a run — the surgical option

Rather than disabling suspend globally, wrap the worker in an inhibitor. The machine
sleeps normally the rest of the time:

```bash
systemd-inhibit --what=idle:sleep --who=ClaudeCron --why="draining the prompt queue" pwsh -NoProfile -c 'Import-Module ClaudeCron; Start-ClaudeCronWorker'
```

See what is currently holding the machine awake, and why:

```bash
systemd-inhibit --list
```

Mint also ships **Caffeine** (`caffeine-indicator`) — a tray toggle that does the same
thing for a while. Fine for an evening, less good for something you want every night.

### The heavy hammer

To make suspend impossible system-wide until you undo it:

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

Undo it with `sudo systemctl unmask` on the same four targets. This is worth knowing
about, but the Power Management setting above is almost always the better answer — a
masked `suspend.target` also means closing the lid does nothing, forever, including when
you have forgotten you did this.

Related, for a laptop: `/etc/systemd/logind.conf` controls the lid switch independently
of the desktop settings. Set `HandleLidSwitch=ignore` and `HandleLidSwitchExternalPower=ignore`,
then `sudo systemctl restart systemd-logind`. Note that restarting logind can end your
graphical session on some setups — do it from a TTY or straight after a reboot.

### Waking up on purpose instead

If you would rather the machine sleep and wake for the reset, `rtcwake` schedules a
hardware wake. To sleep now and wake in five hours:

```bash
sudo rtcwake -m mem -s 18000
```

Pair it with the systemd timer: the machine wakes, the timer fires with `Persistent=true`,
the backlog drains. `-m no` sets the alarm without sleeping, if you want to arm it and
let the desktop suspend on its own schedule.

### Check that it worked

After a night, confirm nothing suspended:

```bash
journalctl -b -u systemd-suspend --no-pager
```

Empty output means the machine stayed up. `Get-ClaudeCronStatus` then tells you whether
the queue actually drained, and `Get-ClaudeCronLog` shows what happened when it did.

---

## Files on disk

Everything lives under `~/.config/claude-cron` (or `$CLAUDE_CRON_HOME`):

```
config.json      settings written by Set-ClaudeCronConfig
state.json       quota block and last drain time
queue/*.json     one file per job — readable, and safe to delete by hand
logs/<id>.log    captured output per job, one appended block per run
logs/claude-cron.log   what the module itself did
logs/cron.log    whatever the scheduled command printed
history.jsonl    one line per finished run, kept after jobs are cleared
worker.lock      pid of the drain in progress
```

Job files are plain JSON on purpose: if something goes wrong you can read the queue with
`cat`, fix a field with an editor, or delete the file.

## Tests

```bash
pwsh -NoProfile -c 'Invoke-Pester -Path ./Test -Output Detailed'
```

43 tests covering the cron parser, interval parsing, quota and auth detection, the job
lifecycle, retries and the quota pause. They run against a throwaway `CLAUDE_CRON_HOME` in the temp
directory and never call the Claude CLI, so they cost no quota and cannot touch your
real queue.

Requires Pester 5+ (`Install-Module Pester -Scope CurrentUser`). Static analysis is
clean:

```bash
pwsh -NoProfile -c 'Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning'
```
