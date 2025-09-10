# FullUpdate Plugin - Copilot Coding Agent Instructions

## Repository Overview

This repository contains **FullUpdate**, a SourcePawn plugin for SourceMod that provides serverside `cl_fullupdate` functionality for Source engine games. The plugin allows forcing full client updates through both console commands and a native API, with proper rate limiting and cross-platform compatibility.

### Core Functionality
- Provides serverside equivalent of client `cl_fullupdate` command
- Implements rate limiting (1-second cooldown per client)
- Exposes native API for other plugins
- Supports multiple Source engine games via gamedata signatures

## Technical Environment

- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ (configured in sourceknight.yaml)
- **Build System**: SourceKnight with GitHub Actions CI/CD
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight
- **Dependencies**: SourceMod, MultiColors (for include files)

## Project Structure

```
├── addons/sourcemod/
│   ├── scripting/
│   │   ├── FullUpdate.sp          # Main plugin source
│   │   └── include/
│   │       └── FullUpdate.inc     # Native API definitions
│   └── gamedata/
│       └── FullUpdate.games.txt   # Cross-platform signatures/offsets
├── .github/
│   ├── workflows/ci.yml           # Build and release automation
│   └── dependabot.yml            # Dependency updates
├── sourceknight.yaml             # Build configuration
└── README.md
```

## Code Standards & Style

### SourcePawn Conventions
- **Pragmas**: Always use `#pragma semicolon 1` and `#pragma newdecls required`
- **Indentation**: 4 spaces (using tabs)
- **Variables**: 
  - `g_` prefix for globals (e.g., `g_iLastFullUpdate`, `g_hGetClient`)
  - camelCase for locals and parameters
  - PascalCase for functions
- **Memory Management**: Use `delete` directly without null checks
- **API Calls**: Implement proper error handling for all SDK calls

### Plugin-Specific Patterns
- **Version Management**: Version defined in `FullUpdate.inc` using major.minor.patch format
- **Client Validation**: Always validate client index, in-game status, and fake client status
- **Rate Limiting**: Implement cooldowns using `GetTime()` comparisons
- **Cross-Platform Support**: Use gamedata signatures for engine compatibility

## Build System

### SourceKnight Configuration
- **File**: `sourceknight.yaml`
- **Target**: Compiles `FullUpdate.sp` to `FullUpdate.smx`
- **Dependencies**: Automatically downloads SourceMod and MultiColors
- **Output**: Places compiled plugin in `/addons/sourcemod/plugins`

### Building Locally
```bash
# SourceKnight build (if available)
sourceknight build

# Manual compilation (alternative)
spcomp addons/sourcemod/scripting/FullUpdate.sp -o=addons/sourcemod/plugins/FullUpdate.smx
```

### CI/CD Pipeline
- **Trigger**: Push, PR, or manual dispatch
- **Build**: Uses `maxime1907/action-sourceknight@v1`
- **Package**: Creates deployable archive with plugin and gamedata
- **Release**: Auto-tags and releases on main/master branch

## Game Data & Compatibility

### Engine Support
- **CSS/Orange Box Valve**: `CBaseServer` signatures and offsets
- **Left 4 Dead/Left 4 Dead 2**: Modified signatures and offsets
- **Cross-Platform**: Windows, Linux, Mac support via different signatures

### Key Signatures
- `CBaseServer::GetClient`: Client retrieval from server
- `CBaseClient::UpdateAcknowledgedFramecount`: Core fullupdate functionality
- `CVEngineServer::CreateFakeClient`: Server address resolution

### Modifying Game Data
When updating `FullUpdate.games.txt`:
1. Test on target games/platforms
2. Verify signature accuracy with game updates
3. Update version in `FullUpdate.inc` if breaking changes
4. Document changes in commit messages

## Native API Development

### Current Native
```cpp
/**
 * Forces a full update (cl_fullupdate) for a client.
 *
 * @param client    Client index
 * @return          True if update was successful, false otherwise
 * @error          Invalid client index, client not in game, or client is fake
 */
native bool ClientFullUpdate(int client);
```

### Adding New Natives
1. Declare in `FullUpdate.inc` with full documentation
2. Implement in `FullUpdate.sp` using `CreateNative()`
3. Add to `AskPluginLoad2()` function
4. Update version numbers appropriately
5. Validate parameters and throw appropriate errors

## Common Development Workflows

### Adding Console Commands
```cpp
RegConsoleCmd("command_name", Command_Handler);
RegAdminCmd("admin_command", Admin_Handler, ADMFLAG_GENERIC);
AddCommandListener(Command_Listener, "existing_command");
```

### SDK Call Implementation
```cpp
StartPrepSDKCall(SDKCall_Raw);
PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "Function::Name");
PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
Handle hCall = EndPrepSDKCall();
```

### Client State Management
```cpp
// Always validate clients
if (client > MaxClients || client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    return false;

// Implement rate limiting
if (g_iLastAction[client] + COOLDOWN_TIME > GetTime())
    return false;
```

## Testing & Validation

### Pre-Release Testing
1. **Compile**: Ensure no warnings or errors
2. **Load Test**: Verify plugin loads on test server
3. **Functionality**: Test console commands and native API
4. **Multi-Client**: Test with multiple connected clients
5. **Cross-Game**: Validate on supported Source engine games

### Performance Considerations
- **Rate Limiting**: Prevent spam/abuse of fullupdate functionality
- **Memory Management**: Proper cleanup of SDK calls and handles
- **Client Validation**: Early returns for invalid states
- **Gamedata Caching**: SDK calls prepared once in `OnPluginStart()`

## Integration Guidelines

### Using This Plugin
```cpp
#include <FullUpdate>

public void OnPluginStart()
{
    // Check if FullUpdate is available
    if (LibraryExists("FullUpdate"))
    {
        // Use ClientFullUpdate(client) as needed
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "FullUpdate") == 0)
    {
        // FullUpdate became available
    }
}
```

### Extending Functionality
- Follow existing patterns for new features
- Maintain backward compatibility in native API
- Document all changes in include file
- Update version numbers for breaking changes

## Troubleshooting

### Common Issues
1. **Gamedata Outdated**: Update signatures after game updates
2. **SDK Call Failures**: Verify gamedata accuracy and game compatibility
3. **Client Validation**: Ensure proper client state checking
4. **Rate Limiting**: Check cooldown implementation

### Debug Approach
1. Enable SourceMod error logging
2. Test on development server with `sv_cheats 1`
3. Verify gamedata signatures with game disassembly tools
4. Use `sm plugins info FullUpdate` for runtime status

## Version Management

- **Include File**: Version defined in `FullUpdate.inc`
- **Format**: `MAJOR.MINOR.PATCH` (currently 1.3.2)
- **Git Tags**: Automated tagging via CI/CD pipeline
- **Breaking Changes**: Increment major version for API changes
- **Features**: Increment minor version for new functionality
- **Fixes**: Increment patch version for bug fixes

This plugin serves as a reference implementation for Source engine interaction and cross-platform SourceMod development patterns.