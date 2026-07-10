/*
 * webhelper_wrapper.c - stands in front of Steam's steamwebhelper.exe and
 * appends the CEF software-rendering flags that fix the black screen under
 * Wine on macOS. Needed cuz Steam FILTERS STEAM_CEF_COMMAND_LINE and drops
 * the decisive --in-process-gpu flag; appending here (last-wins in Chromium's
 * command-line parser) makes it stick and collapses Steam's separate ANGLE
 * GPU process into the main process.
 *
 * Install: rename the real steamwebhelper.exe -> steamwebhelper_real.exe, drop
 * this in as steamwebhelper.exe. Build: x86_64-w64-mingw32-gcc.
 *
 * Adapted from the Vineport project (github.com/MelonForAll/vineport, MIT).
 */
#include <windows.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {
    char cmdline[32768];
    char exepath[MAX_PATH];
    char *lastslash;
    int offset;

    GetModuleFileNameA(NULL, exepath, MAX_PATH);
    lastslash = strrchr(exepath, '\\');
    if (lastslash) *(lastslash + 1) = '\0';

    offset = snprintf(cmdline, sizeof(cmdline), "\"%ssteamwebhelper_real.exe\"", exepath);
    if (offset < 0 || (size_t)offset >= sizeof(cmdline)) return 1;

    // Detect a child re-invocation so we don't append our flags twice.
    int already_patched = 0;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--in-process-gpu") == 0) { already_patched = 1; break; }
    }

    for (int i = 1; i < argc; i++) {
        int needed;
        if (strchr(argv[i], ' ')) {
            needed = snprintf(cmdline + offset, sizeof(cmdline) - offset, " \"%s\"", argv[i]);
        } else {
            needed = snprintf(cmdline + offset, sizeof(cmdline) - offset, " %s", argv[i]);
        }
        if (needed < 0 || (size_t)(offset + needed) >= sizeof(cmdline)) return 1;
        offset += needed;
    }

    if (!already_patched) {
        int needed = snprintf(cmdline + offset, sizeof(cmdline) - offset,
                              " --no-sandbox --in-process-gpu --disable-gpu --disable-gpu-compositing");
        if (needed < 0 || (size_t)(offset + needed) >= sizeof(cmdline)) return 1;
    }

    STARTUPINFOA si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    if (!CreateProcessA(NULL, cmdline, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) return 1;

    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return exitCode;
}
