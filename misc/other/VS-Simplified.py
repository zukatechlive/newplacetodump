"""
Build Doctor v3.0
Dark IDE-style C++ / C# build tool using pywebview for the UI.

Requirements:
    pip install pywebview

Run:
    python build_doctor.py
"""

import os
import re
import subprocess
import threading
import json
import webview

APP_TITLE   = "Build Doctor"
APP_VERSION = "9.0"



# Hardcoded fallback path — used if vswhere auto-detection fails.
VCVARS64_OVERRIDE = r"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"


def get_vswhere_path():
    for env_var in ("ProgramFiles(x86)", "ProgramFiles"):
        program_files = os.environ.get(env_var, "")
        if not program_files:
            continue
        path = os.path.join(
            program_files,
            "Microsoft Visual Studio",
            "Installer",
            "vswhere.exe"
        )
        if os.path.exists(path):
            return path
    return None


def find_vcvars64():
    vswhere = get_vswhere_path()
    if vswhere:
        try:
            result = subprocess.check_output([
                vswhere,
                "-latest",
                "-products", "*",
                "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
                "-property", "installationPath"
            ], text=True).strip()

            if result:
                vcvars = os.path.join(result, "VC", "Auxiliary", "Build", "vcvars64.bat")
                if os.path.exists(vcvars):
                    return vcvars
        except Exception:
            pass

    if os.path.exists(VCVARS64_OVERRIDE):
        return VCVARS64_OVERRIDE

    return None


# ─────────────────────────────────────────────
# Project Scanner
# ─────────────────────────────────────────────

def scan_project(folder):
    result = {
        "cpp": [], "c": [], "headers": [],
        "sln": [], "vcxproj": [], "csproj": [], "cs": [],
        "cmake": [], "makefile": []
    }

    for rootdir, _, files in os.walk(folder):
        for file in files:
            full = os.path.join(rootdir, file)
            rel  = os.path.relpath(full, folder).replace("\\", "/")
            lo   = file.lower()

            if lo.endswith(".cpp"):
                result["cpp"].append(rel)
            elif lo.endswith(".c"):
                result["c"].append(rel)
            elif lo.endswith((".h", ".hpp")):
                result["headers"].append(rel)
            elif lo.endswith(".sln"):
                result["sln"].append(rel)
            elif lo.endswith(".vcxproj"):
                result["vcxproj"].append(rel)
            elif lo.endswith(".csproj"):
                result["csproj"].append(rel)
            elif lo.endswith(".cs"):
                result["cs"].append(rel)
            elif lo == "cmakelists.txt":
                result["cmake"].append(rel)
            elif lo == "makefile":
                result["makefile"].append(rel)

    return result


# ─────────────────────────────────────────────
# Build Script Generation
# ─────────────────────────────────────────────

def generate_vcxproj(folder, config, scan):
    """
    Generate a minimal but complete .vcxproj for a folder that has .cpp/.c
    source files but no existing Visual Studio project file.
    Returns the path to the generated .vcxproj.
    """
    import uuid as _uuid

    proj_name  = os.path.basename(folder.rstrip("\\/")) or "project"
    proj_guid  = "{" + str(_uuid.uuid4()).upper() + "}"
    conf       = config.get("config",  "Release")
    # VS 2026 / MSBuild v144 requires "stdcpp17" format, NOT "c++17"
    # "/std:c++17" -> strip "/std:" -> "c++17" -> map to MSBuild canonical form
    _std_raw = config.get("std", "/std:c++17").replace("/std:", "")  # e.g. "c++17"
    _std_map = {"c++14": "stdcpp14", "c++17": "stdcpp17", "c++20": "stdcpp20",
                "c++latest": "stdcpplatest", "c11": "stdc11", "c17": "stdc17"}
    std = _std_map.get(_std_raw.lower(), "stdcpp17")
    rt         = config.get("runtime", "/MT")
    opt        = config.get("opt",     "/O2")
    extra_inc  = config.get("extraInc", "")
    extra_lib  = config.get("extraLib", "")

    # Build extra include/lib strings for the XML
    inc_parts = [p.strip() for p in extra_inc.split(";") if p.strip()]
    lib_parts = [p.strip() for p in extra_lib.split(";") if p.strip()]
    inc_str   = ";".join(inc_parts + ["%(AdditionalIncludeDirectories)"])
    lib_str   = ";".join(lib_parts + ["%(AdditionalDependencies)"]) if lib_parts else "%(AdditionalDependencies)"

    # Collect source files relative to the project folder
    src_files = scan["cpp"] + scan["c"]

    # Map /O2 → Optimize value
    opt_map = {"/O1": "MinSpace", "/O2": "MaxSpeed", "/Od": "Disabled", "/Ox": "Full"}
    opt_val = opt_map.get(opt, "MaxSpeed")

    # Runtime library: /MT → MultiThreaded, /MD → MultiThreadedDLL, etc.
    rt_map = {"/MT": "MultiThreaded", "/MD": "MultiThreadedDLL",
              "/MTd": "MultiThreadedDebug", "/MDd": "MultiThreadedDebugDLL"}
    rt_val = rt_map.get(rt, "MultiThreaded")

    compile_items = "\n".join(
        f'    <ClCompile Include="{f}" />' for f in src_files
    )

    # Determine if any headers exist to add as ClInclude items
    hdr_items = "\n".join(
        f'    <ClInclude Include="{f}" />' for f in scan["headers"]
    ) if scan["headers"] else ""

    vcxproj_content = f"""<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">

  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="{conf}|x64">
      <Configuration>{conf}</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
  </ItemGroup>

  <PropertyGroup Label="Globals">
    <ProjectGuid>{proj_guid}</ProjectGuid>
    <RootNamespace>{proj_name}</RootNamespace>
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>

  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />

  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='{conf}|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>{"true" if "Debug" in conf else "false"}</UseDebugLibraries>
    <PlatformToolset>v143</PlatformToolset>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>

  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />

  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='{conf}|x64'">
    <OutDir>$(SolutionDir)$(Configuration)\\</OutDir>
    <IntDir>$(Configuration)\\</IntDir>
    <TargetName>{proj_name}</TargetName>
  </PropertyGroup>

  <ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='{conf}|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <Optimization>{opt_val}</Optimization>
      <PreprocessorDefinitions>NDEBUG;_CONSOLE;%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <LanguageStandard>{std}</LanguageStandard>
      <RuntimeLibrary>{rt_val}</RuntimeLibrary>
      <ExceptionHandling>Sync</ExceptionHandling>
      <AdditionalIncludeDirectories>{inc_str}</AdditionalIncludeDirectories>
    </ClCompile>
    <Link>
      <SubSystem>Console</SubSystem>
      <GenerateDebugInformation>{"true" if "Debug" in conf else "false"}</GenerateDebugInformation>
      <AdditionalDependencies>{lib_str}</AdditionalDependencies>
    </Link>
  </ItemDefinitionGroup>

  <ItemGroup>
{compile_items}
  </ItemGroup>
{"  <ItemGroup>" + chr(10) + hdr_items + chr(10) + "  </ItemGroup>" if hdr_items else ""}

  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />

</Project>
"""

    vcxproj_path = os.path.join(folder, f"{proj_name}.vcxproj")
    with open(vcxproj_path, "w", encoding="utf-8") as f:
        f.write(vcxproj_content)

    return vcxproj_path


def generate_build_bat(folder, config):
    vcvars = find_vcvars64()
    if not vcvars:
        raise Exception("Could not find vcvars64.bat — is Visual Studio installed?")

    scan       = scan_project(folder)
    conf       = config.get("config",   "Release")
    extra_inc  = config.get("extraInc", "")
    parallel   = config.get("parallel", True)

    inc_flags        = " ".join(f'/I"{p.strip()}"'       for p in extra_inc.split(";") if p.strip())
    msbuild_parallel = " /m" if parallel else ""

    # ── Auto-generate .vcxproj if we only have raw source files ─────────────
    if not scan["sln"] and not scan["vcxproj"] and (scan["cpp"] or scan["c"]):
        vcxproj_path = generate_vcxproj(folder, config, scan)
        scan["vcxproj"].append(os.path.relpath(vcxproj_path, folder).replace("\\", "/"))

    lines = [
        "@echo off",
        f'cd /d "{folder}"',
        f'call "{vcvars}"',
        "if ERRORLEVEL 1 (",
        "  echo [!] vcvars64.bat failed — Visual Studio environment not loaded.",
        "  exit /b 1",
        ")",
        "echo.",
        "echo === BUILD DOCTOR START ===",
        "echo.",
    ]

    if scan["sln"]:
        sln = scan["sln"][0]
        lines.append(f'MSBuild "{sln}" /p:Configuration={conf}{msbuild_parallel} /nologo /v:m')
        lines.append("if ERRORLEVEL 1 ( echo [!] MSBuild failed. & exit /b 1 )")

    elif scan["vcxproj"]:
        proj = scan["vcxproj"][0]
        lines.append(f'MSBuild "{proj}" /p:Configuration={conf}{msbuild_parallel} /nologo /v:m')
        lines.append("if ERRORLEVEL 1 ( echo [!] MSBuild failed. & exit /b 1 )")

    elif scan["cmake"]:
        lines += [
            "if not exist build mkdir build",
            "cd build",
            f"cmake .. {inc_flags}",
            "if ERRORLEVEL 1 ( echo [!] CMake configure failed. & exit /b 1 )",
            f"cmake --build . --config {conf}",
            "if ERRORLEVEL 1 ( echo [!] CMake build failed. & exit /b 1 )",
        ]

    else:
        lines.append("echo [!] No buildable files found.")
        lines.append("exit /b 1")

    lines += [
        "echo.",
        "echo === BUILD COMPLETE ===",
        "exit /b 0",
    ]

    bat_path = os.path.join(folder, "build.bat")
    with open(bat_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    return bat_path, scan


# ─────────────────────────────────────────────
# Diagnosis Patterns
# ─────────────────────────────────────────────

PATTERNS = [
    # ── C++ compiler errors ───────────────────────────────────────────────────
    (r"fatal error C1083",          "Missing include file — check /I paths or install the dependency."),
    # ── Luau-specific version mismatch errors ────────────────────────────────
    (r"error C2051.*BytecodeUtils",  "Luau version mismatch: BytecodeUtils.h enum changed between versions. Run FIX LUAU to re-sync headers and sources from the same commit."),
    (r"C4003.*LUAU_FASTFLAGVARIABLE","Luau version mismatch: LUAU_FASTFLAGVARIABLE macro signature changed (old: 2 args, new: 1 arg). Run FIX LUAU to sync headers/sources to same commit."),
    (r"C2327.*BytecodeBuilder.*constants|C2065.*hasConstants", "Luau API change: BytecodeBuilder members renamed between versions. Run FIX LUAU to re-sync headers and .cpp files from same repo commit."),
    (r"'LuauBytecodeType'.*undeclared", "Luau version mismatch: LuauBytecodeType moved or renamed. Run FIX LUAU to re-sync all Luau headers from the cloned repo."),
    (r"LNK2001|LNK2019",            "Unresolved external symbol — missing .lib or implementation file."),
    (r"LNK1104",                    "Linker cannot open file — add /LIBPATH or install the missing library."),
    (r"LNK1120",                    "Linker: too many unresolved externals — see preceding LNK2001/LNK2019 errors above."),
    (r"LNK1169",                    "Linker: multiply defined symbol — same symbol defined in multiple .obj files. Check for duplicate .cpp entries."),
    (r"LNK1181",                    "Linker cannot open input file — a required .lib or .obj is missing from the output or lib paths."),
    (r"cannot open file.*\.lib",    "Missing .lib file — add /LIBPATH or install the dependency."),
    (r"'cl' is not recognized",     "MSVC environment not loaded — vcvars64.bat failed or VS not found."),
    (r"'MSBuild' is not recognized","MSBuild not on PATH — run from a VS Developer Command Prompt or let Build Doctor load vcvars64.bat."),
    (r"cmake.*is not recognized",   "CMake not found — install CMake and add to PATH."),
    (r"ninja.*is not recognized",   "Ninja not found — install Ninja build system."),
    (r"\bSDL\b",                    "Possible SDL dependency missing — check SDL2 include/lib paths."),
    (r"openssl",                    "OpenSSL dependency missing — click FIX DEPS to install via vcpkg automatically."),
    (r"ZSTD_decompress|error C3861.*zstd|zstd(?:\.h|/zstd\.h)",
                                    "ZSTD library missing — click FIX DEPS to install via vcpkg automatically."),
    (r"warning C4101",              "C4101: unreferenced local variable — click FIX DEPS to suppress automatically."),
    (r"boost",                      "Possible Boost dependency missing — set BOOST_ROOT or add to include paths."),
    (r"error C2065",                "Undeclared identifier — missing include or wrong namespace."),
    (r"error C2664",                "Type mismatch — function argument type error."),
    (r"error C3861",                "Identifier not found — possible missing include or typo."),
    (r"error C2059",                "C++ syntax error — invalid token in expression. Check for stray characters, misplaced operators, or unclosed strings."),
    (r"error C2143",                "C++ syntax error — missing token before identifier. Likely a missing ';' or unbalanced brace."),
    (r"error C2440",                "C++ type-conversion error — incompatible types. Add an explicit cast or check pointer/reference types."),
    (r"error C2039",                "C++ member not found in type — wrong object type or the required #include for the full class definition is missing."),
    (r"error C4996",                "C++ deprecated function warning elevated to error — use the recommended replacement or add #pragma warning(disable: 4996)."),
    (r"error C4244",                "C++ narrowing conversion warning elevated to error — add an explicit cast to silence it."),
    (r"error C2248",                "C++ cannot access private/protected member — use a public accessor method or add a friend declaration."),
    (r"error C2027",                "C++ use of undefined type — forward declaration found but full definition needed here. Add the correct #include."),
    (r"error C3646",                "C++ unknown override specifier — 'override'/'final' require /std:c++11 or later. Update the C++ Standard in Settings."),
    (r"error C2220",                "C++ warning treated as error (/WX flag) — fix the underlying warnings or remove /WX from compiler flags."),
    (r"error C1010",                "C++ unexpected end of file while looking for precompiled header — add #include \"pch.h\" (or stdafx.h) as first line, or disable PCH."),
    (r"error C2007",                "#define syntax error — malformed macro definition."),
    (r"error C2001",                "Newline in constant — an unclosed string literal spans across lines. Check for a missing closing quote."),
    # ── C# / MSBuild errors ───────────────────────────────────────────────────
    (r"error CS2001",               "C# source file not found — a .csproj references a .cs file that is missing or moved. Auto-fix available: run Fix CS Files."),
    (r"error CS0246",               "C# type or namespace not found — missing using directive or assembly reference. Auto-fix available: run Fix CS Files."),
    (r"error CS0234",               "C# namespace member not found — check using directives and assembly references."),
    (r"error CS1061",               "C# member does not exist — possible API change or wrong object type."),
    (r"error CS0103",               "C# name does not exist in context — missing using directive or undeclared variable."),
    (r"error CS1503",               "C# argument type mismatch — wrong type passed to a method."),
    (r"error CS0029",               "C# implicit conversion error — incompatible types assigned."),
    (r"error CS0117",               "C# member not found on type — check spelling or assembly reference."),
    (r"error CS0122",               "C# inaccessible member — check access modifiers (private/internal)."),
    (r"error CS1002",               "C# syntax error: expected semicolon — check for missing ';'."),
    (r"error CS1513",               "C# syntax error: expected closing brace — check brace matching."),
    (r"error CS8019",               "C# unnecessary using directive — can be cleaned up safely."),
    (r"error CS0006",               "C# metadata file not found — a referenced DLL is missing from disk. Check Reference HintPaths in .csproj."),
    (r"error CS0115",               "C# override has no matching base method — base class may have changed. Verify the method signature matches."),
    (r"error CS0120",               "C# object reference required — calling an instance member from a static context. Add 'static' to the method or create an instance."),
    (r"error CS0260",               "C# partial class declaration mismatch — all partial declarations must use the same access modifier."),
    (r"error CS7036",               "C# required argument not supplied — a method call is missing one or more required parameters."),
    (r"error CS8632",               "C# nullable annotation requires nullable context — add '#nullable enable' or set <Nullable>enable</Nullable> in .csproj."),
    (r"error CS0579",               "C# duplicate attribute — same attribute applied more than once where only one is allowed."),
    (r"error CS1579",               "C# foreach not applicable — the collection type does not implement IEnumerable. Check the type or add GetEnumerator()."),
    (r"error CS0433",               "C# ambiguous reference — same type defined in multiple assemblies. Remove the duplicate reference or use extern alias."),
    (r"error CS0266",               "C# explicit cast required — cannot implicitly convert between these types. Add an explicit cast."),
    (r"error CS0305",               "C# wrong number of type arguments — check generic type parameter count."),
    (r"error CS0411",               "C# type arguments cannot be inferred — provide explicit type arguments for the generic method call."),
    (r"error CS1061",               "C# member does not exist on type — possible API change or wrong target type."),
    (r"The referenced component .* could not be found",
                                    "MSBuild reference not found — a NuGet package or DLL is missing. Run NuGet Restore or check .csproj references."),
    (r"NU1903|NU1904",              "NuGet vulnerability warning — consider upgrading the flagged package(s)."),
    (r"NU1101|NU1102|NU1103",       "NuGet package not found — package ID or version may not exist in any configured feed. Check nuget.config sources."),
    (r"packages\.config.*not found|restore.*package|NuGet.*restore",
                                    "NuGet packages not restored — click 'NuGet Restore' in the sidebar or run 'dotnet restore' in a terminal."),
    (r"error MSB3073",              "MSBuild: command-line task exited non-zero — check PreBuild/PostBuild event commands for errors."),
    (r"error MSB4019",              "MSBuild: imported .targets/.props file not found — a NuGet package or SDK is missing. Try NuGet Restore."),
    (r"error MSB3021",              "MSBuild: unable to copy file — output file may be locked by a running process. Close the app/debugger and rebuild."),
    (r"error MSB3026",              "MSBuild: file copy failed after retries — close anything locking the output DLL/EXE, then rebuild."),
    (r"error MSB4006",              "MSBuild: circular dependency detected in the project — check ProjectReference loops."),
    (r"MSBUILD : error",            "MSBuild engine error — check the project file for malformed XML or a missing import target."),
    (r"NETSDK1045",                 ".NET SDK does not support this TargetFramework — install a newer .NET SDK that targets the required version."),
    (r"NETSDK1138",                 "TargetFramework is out of support — update <TargetFramework> to a currently supported version."),
    (r"NETSDK1004",                 "assets.json not found — run 'dotnet restore' to regenerate it."),
    (r"Could not load file or assembly",
                                    "Assembly load failure — DLL missing or wrong architecture (x86 vs x64). Check output directory and project references."),
    (r"The type initializer for .* threw an exception",
                                    "Static initializer exception — a static constructor or static field initializer crashed. Check for null refs or missing config."),
    (r"access.*denied|permission.*denied",
                                    "File access denied — output file may be locked by another process (debugger, running app). Close it and rebuild."),
    (r"disk.*full|no space left",   "Disk is full — free up space on the output drive."),
    (r"error MSB3202",              "MSB3202: Project file referenced in .sln not found on disk — auto-fix available: run FIX MSB3202 to generate the missing project file or remove the dead .sln reference."),
]


# ─────────────────────────────────────────────
# XML Helpers (shared by all .csproj fixers)
# ─────────────────────────────────────────────

def _parse_csproj(path):
    """Return (ET.ElementTree, root, xmlns_uri) or raise."""
    import xml.etree.ElementTree as ET
    tree = ET.parse(path)
    root = tree.getroot()
    m    = re.match(r"^\{(.*?)\}", root.tag)
    xmlns = m.group(1) if m else ""
    return tree, root, xmlns


def _tag(xmlns, name):
    return f"{{{xmlns}}}{name}" if xmlns else name


def _strip_ns(tag):
    return re.sub(r"^\{.*?\}", "", tag)


def _write_csproj(tree, path, xmlns):
    import xml.etree.ElementTree as ET
    if xmlns:
        ET.register_namespace("", xmlns)
    tree.write(path, encoding="utf-8", xml_declaration=True)


# ─────────────────────────────────────────────
# Auto-Fix Pass 1 & 2: CS2001 + CS0246
# ─────────────────────────────────────────────

def fix_missing_cs_files(folder):
    """
    Pass 1 — CS2001:
      Remove <Compile Include="..."/> entries whose .cs file is gone from disk.

    Pass 2 — CS0246 / missing ProjectReference:
      For each .csproj, detect namespaces/types used in .cs files that aren't
      locally defined, then add <ProjectReference> to matching sibling projects.
    """
    import xml.etree.ElementTree as ET

    actions = []

    all_csproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".csproj"):
                all_csproj.append(os.path.join(rootdir, fname))

    if not all_csproj:
        return ["No .csproj files found under the selected folder."]

    sibling_map = {}
    for cp in all_csproj:
        stem = os.path.splitext(os.path.basename(cp))[0]
        sibling_map[stem.lower()] = cp

    # ── Pass 1: remove dead <Compile> entries ────────────────────────────────
    for csproj_path in all_csproj:
        proj_dir = os.path.dirname(csproj_path)
        fname    = os.path.basename(csproj_path)
        try:
            tree, root, xmlns = _parse_csproj(csproj_path)
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        removed = []
        for ig in root.iter(_tag(xmlns, "ItemGroup")):
            to_remove = []
            for child in list(ig):
                if _strip_ns(child.tag) != "Compile":
                    continue
                include = child.attrib.get("Include", "")
                if not include.lower().endswith(".cs"):
                    continue
                abs_cs = os.path.normpath(
                    os.path.join(proj_dir, include.replace("\\", os.sep))
                )
                if not os.path.exists(abs_cs):
                    to_remove.append((ig, child, include))
            for ig2, ch, inc in to_remove:
                ig2.remove(ch)
                removed.append(inc)

        if removed:
            _write_csproj(tree, csproj_path, xmlns)
            for inc in removed:
                actions.append(f"[FIXED-CS2001] {fname}: removed dead Compile ref → {inc}")
        else:
            actions.append(f"[OK] {fname}: no dead Compile references.")

    # ── Pass 2: detect & fix missing ProjectReferences (CS0246) ──────────────
    for csproj_path in all_csproj:
        proj_dir = os.path.dirname(csproj_path)
        fname    = os.path.basename(csproj_path)
        stem     = os.path.splitext(fname)[0]

        try:
            tree, root, xmlns = _parse_csproj(csproj_path)
        except ET.ParseError:
            continue

        existing_refs = set()
        for el in root.iter(_tag(xmlns, "ProjectReference")):
            existing_refs.add(
                os.path.normpath(
                    os.path.join(proj_dir,
                                 el.attrib.get("Include", "").replace("\\", os.sep))
                ).lower()
            )

        cs_files = []
        for el in root.iter(_tag(xmlns, "Compile")):
            inc = el.attrib.get("Include", "")
            if inc.lower().endswith(".cs"):
                abs_cs = os.path.normpath(
                    os.path.join(proj_dir, inc.replace("\\", os.sep))
                )
                if os.path.exists(abs_cs):
                    cs_files.append(abs_cs)

        if not cs_files:
            continue

        used_roots = set()
        using_pat  = re.compile(r"^\s*using\s+([\w]+)", re.MULTILINE)
        dotted_pat = re.compile(r"\b([A-Z][A-Za-z0-9_]+)\s*\.")

        for cs in cs_files:
            try:
                src = open(cs, encoding="utf-8", errors="ignore").read()
            except OSError:
                continue
            for m in using_pat.finditer(src):
                used_roots.add(m.group(1).lower())
            for m in dotted_pat.finditer(src):
                used_roots.add(m.group(1).lower())

        used_roots.discard(stem.lower())

        import xml.etree.ElementTree as ET
        added = []
        for candidate_name, candidate_path in sibling_map.items():
            if candidate_name == stem.lower():
                continue
            if candidate_name not in used_roots:
                continue
            norm_candidate = os.path.normpath(candidate_path).lower()
            if norm_candidate in existing_refs:
                continue

            rel            = os.path.relpath(candidate_path, proj_dir)
            candidate_dir  = os.path.dirname(candidate_path)
            candidate_stem = os.path.splitext(os.path.basename(candidate_path))[0]
            dll_hint       = None
            for conf in ("Release", "Debug"):
                for arch in ("x64", "x86", ""):
                    dll_search = os.path.join(
                        candidate_dir, "bin",
                        arch, conf,
                        candidate_stem + ".dll"
                    ) if arch else os.path.join(
                        candidate_dir, "bin", conf, candidate_stem + ".dll"
                    )
                    if os.path.exists(dll_search):
                        dll_hint = dll_search
                        break
                if dll_hint:
                    break

            target_ig = None
            for ig in root.iter(_tag(xmlns, "ItemGroup")):
                for ch in ig:
                    if _strip_ns(ch.tag) == "ProjectReference":
                        target_ig = ig
                        break
                if target_ig is not None:
                    break
            if target_ig is None:
                target_ig = ET.SubElement(root, _tag(xmlns, "ItemGroup"))

            pr = ET.SubElement(target_ig, _tag(xmlns, "ProjectReference"))
            pr.set("Include", rel)
            pr_name      = ET.SubElement(pr, _tag(xmlns, "Name"))
            pr_name.text = candidate_stem

            if dll_hint:
                ref_ig  = ET.SubElement(root, _tag(xmlns, "ItemGroup"))
                ref_el  = ET.SubElement(ref_ig, _tag(xmlns, "Reference"))
                ref_el.set("Include", candidate_stem)
                hint      = ET.SubElement(ref_el, _tag(xmlns, "HintPath"))
                hint.text = os.path.relpath(dll_hint, proj_dir)

            existing_refs.add(norm_candidate)
            added.append(candidate_stem)

        if added:
            _write_csproj(tree, csproj_path, xmlns)
            for a in added:
                actions.append(f"[FIXED-CS0246] {fname}: added ProjectReference → {a}")
        else:
            matches = [n for n in used_roots if n in sibling_map and n != stem.lower()]
            if not matches:
                actions.append(f"[OK] {fname}: no missing project references detected.")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 3: Duplicate References + Empty ItemGroups
# ─────────────────────────────────────────────

def fix_duplicate_refs(folder):
    """
    Scans all .csproj files and:
      - Removes duplicate <Reference>, <PackageReference>, <Compile>,
        <None>, <Content>, <EmbeddedResource> entries (same Include= value).
      - Removes completely empty <ItemGroup> nodes.
    Returns a list of human-readable action strings.
    """
    import xml.etree.ElementTree as ET
    actions    = []
    DUPE_TAGS  = ("Reference", "PackageReference", "Compile", "None",
                  "Content", "EmbeddedResource", "Analyzer")

    all_csproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".csproj"):
                all_csproj.append(os.path.join(rootdir, fname))

    if not all_csproj:
        return ["No .csproj files found."]

    for csproj_path in all_csproj:
        fname   = os.path.basename(csproj_path)
        try:
            tree, root, xmlns = _parse_csproj(csproj_path)
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        changed    = False
        dup_count  = 0
        empty_count = 0

        # Pass A: remove duplicate item entries per tag type
        for tag_name in DUPE_TAGS:
            seen = {}
            for ig in root.iter(_tag(xmlns, "ItemGroup")):
                to_remove = []
                for child in list(ig):
                    if _strip_ns(child.tag) != tag_name:
                        continue
                    inc = child.attrib.get("Include", "").strip().lower()
                    if not inc:
                        continue
                    if inc in seen:
                        to_remove.append((ig, child, child.attrib.get("Include", "")))
                    else:
                        seen[inc] = child
                for ig2, ch, orig_inc in to_remove:
                    ig2.remove(ch)
                    dup_count += 1
                    changed    = True
                    actions.append(
                        f"[FIXED-DUP] {fname}: removed duplicate "
                        f"<{tag_name} Include=\"{orig_inc}\" />"
                    )

        # Pass B: remove empty <ItemGroup> nodes
        for ig in list(root):
            if _strip_ns(ig.tag) == "ItemGroup" and len(ig) == 0:
                root.remove(ig)
                empty_count += 1
                changed      = True

        if changed:
            _write_csproj(tree, csproj_path, xmlns)
            if empty_count:
                actions.append(f"[FIXED-EMPTY] {fname}: removed {empty_count} empty <ItemGroup>(s).")

        if dup_count == 0 and empty_count == 0:
            actions.append(f"[OK] {fname}: no duplicate references or empty item groups.")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 4: Missing AssemblyName / RootNamespace
# ─────────────────────────────────────────────

def fix_assembly_metadata(folder):
    """
    For old-style .csproj files that have a <PropertyGroup> but are missing
    <AssemblyName> or <RootNamespace>, inserts them using the project filename stem.
    SDK-style projects (those that use <Project Sdk=...>) are skipped as they
    default these values automatically.
    Returns a list of action strings.
    """
    import xml.etree.ElementTree as ET
    actions = []

    all_csproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".csproj"):
                all_csproj.append(os.path.join(rootdir, fname))

    if not all_csproj:
        return ["No .csproj files found."]

    for csproj_path in all_csproj:
        fname = os.path.basename(csproj_path)
        stem  = os.path.splitext(fname)[0]
        try:
            tree, root, xmlns = _parse_csproj(csproj_path)
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        # Skip SDK-style projects — they auto-set assembly metadata
        sdk_attr = root.attrib.get("Sdk", "")
        if sdk_attr:
            actions.append(f"[SKIP] {fname}: SDK-style project, assembly metadata auto-set.")
            continue

        changed = False

        # Find the first non-conditional PropertyGroup
        target_pg = None
        for pg in root.iter(_tag(xmlns, "PropertyGroup")):
            if not pg.attrib.get("Condition", ""):
                target_pg = pg
                break

        if target_pg is None:
            actions.append(f"[SKIP] {fname}: no unconditional PropertyGroup found.")
            continue

        for meta_tag in ("AssemblyName", "RootNamespace"):
            existing = target_pg.find(_tag(xmlns, meta_tag))
            if existing is None:
                new_el      = ET.SubElement(target_pg, _tag(xmlns, meta_tag))
                new_el.text = stem
                changed     = True
                actions.append(f"[FIXED-META] {fname}: added <{meta_tag}>{stem}</{meta_tag}>.")
            elif not (existing.text or "").strip():
                existing.text = stem
                changed       = True
                actions.append(f"[FIXED-META] {fname}: filled blank <{meta_tag}> with '{stem}'.")

        if changed:
            _write_csproj(tree, csproj_path, xmlns)
        else:
            actions.append(f"[OK] {fname}: AssemblyName and RootNamespace already set.")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 5: C++ Header Include Guards
# ─────────────────────────────────────────────

def fix_cpp_headers(folder):
    """
    Scans all .h / .hpp files. If a file has no include guard
    (#pragma once or #ifndef ... #define ...), prepends '#pragma once' to it.
    Returns a list of action strings.
    """
    actions     = []
    guard_pat   = re.compile(
        r"#\s*pragma\s+once|#\s*ifndef\s+\w+|#\s*if\s+!defined",
        re.IGNORECASE
    )
    headers_found = 0

    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if not fname.lower().endswith((".h", ".hpp")):
                continue
            full          = os.path.join(rootdir, fname)
            rel           = os.path.relpath(full, folder).replace("\\", "/")
            headers_found += 1
            try:
                with open(full, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                if guard_pat.search(content):
                    actions.append(f"[OK] {rel}: include guard already present.")
                    continue
                # Strip UTF-8 BOM if present before prepending
                if content.startswith("\ufeff"):
                    content = content[1:]
                with open(full, "w", encoding="utf-8") as f:
                    f.write("#pragma once\n\n" + content)
                actions.append(f"[FIXED-HDR] {rel}: added #pragma once.")
            except OSError as exc:
                actions.append(f"[ERROR] {rel}: {exc}")

    if headers_found == 0:
        actions.append("No .h / .hpp files found in the project folder.")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 6 (C++): Missing Include Directories (C1083)
# ─────────────────────────────────────────────

def fix_cpp_missing_includes(folder, last_build_output=""):
    """
    Detects C1083 'Cannot open include file' errors from build output,
    searches the project tree for those headers, and injects the found
    directories into AdditionalIncludeDirectories in every .vcxproj.

    Also performs a blanket scan: any header that lives under the project
    folder but whose parent directory is NOT already in the vcxproj include
    paths will be added.

    Returns a list of action strings.
    """
    import xml.etree.ElementTree as ET

    actions = []

    # ── Step 1: collect missing header names from C1083 lines ────────────────
    missing_names = set()
    c1083_pat = re.compile(
        r"error C1083[^:]*:.*?'([^']+\.h(?:pp)?)'",
        re.IGNORECASE
    )
    for m in c1083_pat.finditer(last_build_output):
        # Strip any leading path components — we only need the filename
        missing_names.add(os.path.basename(m.group(1).replace("/", os.sep).replace("\\", os.sep)))

    if not missing_names and not last_build_output:
        actions.append("[INFO] No build output supplied — running blanket include-path scan instead.")
    elif missing_names:
        actions.append(f"[INFO] C1083 headers to locate: {', '.join(sorted(missing_names))}")

    # ── Step 2: find all .vcxproj files ──────────────────────────────────────
    all_vcxproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    if not all_vcxproj:
        actions.append("[SKIP] No .vcxproj files found under the selected folder.")
        return actions

    # ── Step 3: build a map  header_name -> set of directories ───────────────
    # Walk the whole project tree and record every .h / .hpp location.
    # Expanded skip list covers all common MSVC/CMake output directory names
    # so we never accidentally inject build-artifact paths as include dirs.
    _BLANKET_SKIP = {
        "x64", "x86", "win32", "arm", "arm64",
        "debug", "release", "relwithdebinfo", "minsizerel",
        ".git", ".vs", ".vscode", ".idea",
        "__pycache__", "build", "cmake_install",
        "cmakefiles", "ipch", ".cache",
        "int",           # MSBuild intermediate dir
        "obj",           # common intermediate dir
        "out",           # common output dir
        "bin", "dist",   # distribution/output dirs
        "packages",      # NuGet packages
        "node_modules",  # just in case
    }
    header_dir_map = {}   # filename.lower() -> set of abs dir paths
    for rootdir, dirs, files in os.walk(folder):
        dirs[:] = [d for d in dirs if d.lower() not in _BLANKET_SKIP]
        for fname in files:
            if fname.lower().endswith((".h", ".hpp")):
                key = fname.lower()
                header_dir_map.setdefault(key, set()).add(rootdir)

    # ── Step 4: resolve which dirs need to be added ──────────────────────────
    needed_dirs = set()

    if missing_names:
        for hname in missing_names:
            found = header_dir_map.get(hname.lower(), set())
            if found:
                for d in found:
                    needed_dirs.add(d)
                    actions.append(f"[FOUND] '{hname}' → {d}")
            else:
                actions.append(f"[WARN] '{hname}' not found anywhere under {folder} — add it manually.")
    else:
        # Blanket mode: collect every directory that has headers
        for dirs in header_dir_map.values():
            needed_dirs.update(dirs)

    if not needed_dirs:
        actions.append("[OK] No new include directories to add.")
        return actions

    # ── Step 5: patch each .vcxproj ──────────────────────────────────────────
    for vcxproj_path in all_vcxproj:
        proj_dir = os.path.dirname(vcxproj_path)
        fname    = os.path.basename(vcxproj_path)

        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def tag(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        # Gather existing AdditionalIncludeDirectories values so we don't dupe
        existing_dirs = set()
        for aidEl in root.iter(tag("AdditionalIncludeDirectories")):
            for part in re.split(r"[;,]", aidEl.text or ""):
                part = part.strip().rstrip(os.sep + "/")
                if part and part not in ("%(AdditionalIncludeDirectories)",):
                    # Resolve relative to vcxproj dir
                    abs_p = os.path.normpath(os.path.join(proj_dir, part))
                    existing_dirs.add(abs_p.lower())

        new_dirs = [
            d for d in sorted(needed_dirs)
            if os.path.normpath(d).lower() not in existing_dirs
        ]

        if not new_dirs:
            actions.append(f"[OK] {fname}: all required include paths already present.")
            continue

        # Convert to paths relative to the .vcxproj directory
        rel_dirs = []
        for d in new_dirs:
            try:
                rel = os.path.relpath(d, proj_dir)
            except ValueError:
                rel = d   # Different drive — keep absolute
            rel_dirs.append(rel)

        new_inc_str = ";".join(rel_dirs) + ";%(AdditionalIncludeDirectories)"

        # Find all ClCompile PropertyGroup / ItemDefinitionGroup elements
        # that already have AdditionalIncludeDirectories and update them,
        # OR inject into the first ItemDefinitionGroup/ClCompile we find.
        updated = 0
        for idg in root.iter(tag("ItemDefinitionGroup")):
            for clc in idg.iter(tag("ClCompile")):
                aid = clc.find(tag("AdditionalIncludeDirectories"))
                if aid is not None:
                    existing_text = (aid.text or "").rstrip(";")
                    # Remove the trailing sentinel if present
                    existing_text = existing_text.replace(";%(AdditionalIncludeDirectories)", "").rstrip(";")
                    # Append only truly new dirs
                    parts = [p for p in existing_text.split(";") if p.strip()]
                    for rel in rel_dirs:
                        abs_new = os.path.normpath(os.path.join(proj_dir, rel)).lower()
                        if abs_new not in existing_dirs:
                            parts.append(rel)
                    aid.text = ";".join(parts) + ";%(AdditionalIncludeDirectories)"
                    updated += 1
                else:
                    # Create the element
                    new_el      = ET.SubElement(clc, tag("AdditionalIncludeDirectories"))
                    new_el.text = new_inc_str
                    updated += 1

        if updated == 0:
            # No ClCompile found — inject a new ItemDefinitionGroup
            idg_new = ET.SubElement(root, tag("ItemDefinitionGroup"))
            clc_new = ET.SubElement(idg_new, tag("ClCompile"))
            aid_new = ET.SubElement(clc_new, tag("AdditionalIncludeDirectories"))
            aid_new.text = new_inc_str
            updated = 1

        # Write back
        if xmlns:
            ET.register_namespace("", xmlns)
        tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)

        rel_summary = ", ".join(rel_dirs)
        actions.append(f"[FIXED-INCS] {fname}: injected {len(rel_dirs)} path(s) → {rel_summary}")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 7: Luau / missing git submodule
# ─────────────────────────────────────────────

# Known Luau header → the subdir inside the Luau repo that contains it
_LUAU_HEADER_DIRS = {
    # ── Flat top-level include (Luau/include/Luau/) ──────────────────────────
    "parseoptions.h":    "include",
    "ast.h":             "Ast/include",
    "bytecodeutils.h":   "Bytecode/include",
    "location.h":        "Ast/include",
    "lexer.h":           "Ast/include",
    "parser.h":          "Ast/include",
    "compiler.h":        "Compiler/include",
    "bytecodebuilder.h": "Compiler/include",
    "codegen.h":         "CodeGen/include",
    "config.h":          "Analysis/include",
    "typecheck.h":       "Analysis/include",
    "frontend.h":        "Analysis/include",
    "common.h":          "Common/include",
    "stringutils.h":     "Common/include",
    "bytecode.h":        "Bytecode/include",
    # ── VM / C-API headers (required for lua_newstate, luau_compile, etc.) ───
    "lua.h":             "VM/include",
    "luaconf.h":         "VM/include",
    "lualib.h":          "VM/include",
    "luacode.h":         "Compiler/include",   # luau_compile lives here
    "luacodegen.h":      "CodeGen/include",
    "lapi.h":            "VM/src",
    "ldo.h":             "VM/src",
    "lgc.h":             "VM/src",
    "lobject.h":         "VM/src",
    "lstate.h":          "VM/src",
    "lstring.h":         "VM/src",
    "ltable.h":          "VM/src",
    "lmem.h":            "VM/src",
    "ldebug.h":          "VM/src",
    "lfunc.h":           "VM/src",
    "lvm.h":             "VM/src",
}

# Luau .cpp source file name → path inside repo where it lives
# (relative to luau_dir root)
_LUAU_SOURCE_MAP = {
    # ── Compiler ─────────────────────────────────────────────────────────────
    "compiler.cpp":        "Compiler/src/Compiler.cpp",
    "confusables.cpp":     "Compiler/src/Confusables.cpp",
    "constantfolding.cpp": "Compiler/src/ConstantFolding.cpp",
    "costmodel.cpp":       "Compiler/src/CostModel.cpp",
    "valuetracking.cpp":   "Compiler/src/ValueTracking.cpp",
    "bytecodebuilder.cpp": "Compiler/src/BytecodeBuilder.cpp",
    # ── Ast ──────────────────────────────────────────────────────────────────
    "lexer.cpp":           "Ast/src/Lexer.cpp",
    "location.cpp":        "Ast/src/Location.cpp",
    "parser.cpp":          "Ast/src/Parser.cpp",
    "stringutils.cpp":     "Ast/src/StringUtils.cpp",
    "tableshape.cpp":      "Ast/src/TableShape.cpp",
    "timetrace.cpp":       "Ast/src/TimeTrace.cpp",
    "types.cpp":           "Ast/src/Types.cpp",
    # ── Bytecode ─────────────────────────────────────────────────────────────
    "bytecodeutils.cpp":   "Bytecode/src/BytecodeUtils.cpp",
    # ── VM (required for lua_newstate / luau_load) ───────────────────────────
    "lapi.cpp":            "VM/src/lapi.cpp",
    "laux.cpp":            "VM/src/laux.cpp",
    "lbaselib.cpp":        "VM/src/lbaselib.cpp",
    "lbitlib.cpp":         "VM/src/lbitlib.cpp",
    "lbuflib.cpp":         "VM/src/lbuflib.cpp",
    "lbuiltins.cpp":       "VM/src/lbuiltins.cpp",
    "lcorolib.cpp":        "VM/src/lcorolib.cpp",
    "ldblib.cpp":          "VM/src/ldblib.cpp",
    "ldebug.cpp":          "VM/src/ldebug.cpp",
    "ldo.cpp":             "VM/src/ldo.cpp",
    "lfunc.cpp":           "VM/src/lfunc.cpp",
    "lgc.cpp":             "VM/src/lgc.cpp",
    "linit.cpp":           "VM/src/linit.cpp",
    "liolib.cpp":          "VM/src/liolib.cpp",
    "lmathlib.cpp":        "VM/src/lmathlib.cpp",
    "lmem.cpp":            "VM/src/lmem.cpp",
    "lobject.cpp":         "VM/src/lobject.cpp",
    "loslib.cpp":          "VM/src/loslib.cpp",
    "lstate.cpp":          "VM/src/lstate.cpp",
    "lstring.cpp":         "VM/src/lstring.cpp",
    "lstrlib.cpp":         "VM/src/lstrlib.cpp",
    "ltable.cpp":          "VM/src/ltable.cpp",
    "ltablib.cpp":         "VM/src/ltablib.cpp",
    "ltm.cpp":             "VM/src/ltm.cpp",
    "ludata.cpp":          "VM/src/ludata.cpp",
    "lutf8lib.cpp":        "VM/src/lutf8lib.cpp",
    "lvmexecute.cpp":      "VM/src/lvmexecute.cpp",
    "lvmload.cpp":         "VM/src/lvmload.cpp",
    "lvmutils.cpp":        "VM/src/lvmutils.cpp",
    # ── Common ───────────────────────────────────────────────────────────────
    "lcode.cpp":           "Compiler/src/lcode.cpp",
}

# Alternative paths tried if the primary mapping is not found on disk
_LUAU_SOURCE_ALT = {
    "compiler.cpp":        ["Compiler/src/compiler.cpp"],
    "lexer.cpp":           ["Ast/src/lexer.cpp"],
    "parser.cpp":          ["Ast/src/parser.cpp"],
    "lcode.cpp":           ["Compiler/src/Lcode.cpp", "VM/src/lcode.cpp"],
    "confusables.cpp":     ["Compiler/src/confusables.cpp"],
    "constantfolding.cpp": ["Compiler/src/Constantfolding.cpp"],
    "costmodel.cpp":       ["Compiler/src/Costmodel.cpp"],
    "location.cpp":        ["Ast/src/location.cpp"],
    "stringutils.cpp":     ["Ast/src/Stringutils.cpp", "Common/src/StringUtils.cpp"],
    "tableshape.cpp":      ["Ast/src/Tableshape.cpp"],
    "timetrace.cpp":       ["Ast/src/Timetrace.cpp", "Common/src/TimeTrace.cpp"],
    "types.cpp":           ["Ast/src/types.cpp"],
    "valuetracking.cpp":   ["Compiler/src/Valuetracking.cpp"],
    "bytecodebuilder.cpp": ["Compiler/src/Bytecodebuilder.cpp"],
    "bytecodeutils.cpp":   ["Bytecode/src/Bytecodeutils.cpp"],
    # VM alternates (case variations across OS/clone)
    "lapi.cpp":            ["VM/src/Lapi.cpp"],
    "laux.cpp":            ["VM/src/Laux.cpp"],
    "lbaselib.cpp":        ["VM/src/Lbaselib.cpp"],
    "lbuiltins.cpp":       ["VM/src/Lbuiltins.cpp"],
    "ldebug.cpp":          ["VM/src/Ldebug.cpp"],
    "ldo.cpp":             ["VM/src/Ldo.cpp"],
    "lfunc.cpp":           ["VM/src/Lfunc.cpp"],
    "lgc.cpp":             ["VM/src/Lgc.cpp"],
    "linit.cpp":           ["VM/src/Linit.cpp"],
    "lmem.cpp":            ["VM/src/Lmem.cpp"],
    "lobject.cpp":         ["VM/src/Lobject.cpp"],
    "lstate.cpp":          ["VM/src/Lstate.cpp"],
    "lstring.cpp":         ["VM/src/Lstring.cpp"],
    "ltable.cpp":          ["VM/src/Ltable.cpp"],
    "ltm.cpp":             ["VM/src/Ltm.cpp"],
    "lvmexecute.cpp":      ["VM/src/Lvmexecute.cpp", "VM/src/lvm.cpp", "VM/src/Lvm.cpp"],
    "lvmload.cpp":         ["VM/src/Lvmload.cpp"],
    "lvmutils.cpp":        ["VM/src/Lvmutils.cpp"],
}

# xxhash lives inside Luau's extern directory
_XXHASH_DIRS = ["extern/xxhash", "extern/xxHash", "Extern/xxhash"]

_LUAU_REPO = "https://github.com/luau-lang/luau.git"

# Headers that are bundled inside the Luau include/Luau/ flat layout
_LUAU_FLAT_HEADERS = {
    "parseoptions.h", "ast.h", "location.h", "lexer.h", "parser.h",
    "compiler.h", "bytecodebuilder.h", "bytecodeutils.h",
}

_LUAU_KNOWN_NAMES = set(_LUAU_HEADER_DIRS.keys()) | set(_LUAU_SOURCE_MAP.keys())


def _is_luau_file(name: str) -> bool:
    return name.lower() in _LUAU_KNOWN_NAMES


def _find_git_root(start: str):
    """Walk up from start looking for a .git directory."""
    cur = os.path.abspath(start)
    while True:
        if os.path.exists(os.path.join(cur, ".git")):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def _run_git(args, cwd, timeout=300):
    """Run a git command; return (returncode, stdout+stderr)."""
    try:
        proc = subprocess.run(
            ["git"] + args,
            cwd=cwd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            timeout=timeout,
        )
        return proc.returncode, (proc.stdout or "") + (proc.stderr or "")
    except FileNotFoundError:
        return -1, "'git' not found — install Git and add it to PATH."
    except subprocess.TimeoutExpired:
        return -1, f"git {' '.join(args)} timed out after {timeout}s."
    except Exception as exc:
        return -1, str(exc)


def _find_file_in_repo(luau_dir, filename_lower, primary_rel, alt_rels):
    """
    Try primary path first, then alternates, then a full walk.
    Returns absolute path if found, else None.
    """
    import shutil
    candidates = [primary_rel] + (alt_rels or [])
    for rel in candidates:
        p = os.path.join(luau_dir, rel.replace("/", os.sep))
        if os.path.isfile(p):
            return p
    # Full repo walk fallback
    for rootdir, subdirs, files in os.walk(luau_dir):
        subdirs[:] = [d for d in subdirs if d.lower() not in (".git", "build", "x64")]
        for f in files:
            if f.lower() == filename_lower:
                return os.path.join(rootdir, f)
    return None


def fix_luau_submodule(folder, last_build_output="", emit_line=None):
    """
    Full auto-fix for Luau dependency errors:

      1. Parses C1083 errors for BOTH missing .h headers and missing .cpp sources.
      2. Finds/initializes the Luau git submodule, or clones it fresh.
      3. Copies missing .cpp source files from the Luau repo into the project's
         src/Luau/ directory (creating it if needed).
      4. Patches every .vcxproj to add:
           a) The required Luau include paths (AdditionalIncludeDirectories)
           b) ClCompile entries for any newly copied .cpp source files
      5. Handles xxhash.h by injecting the Luau extern/xxhash include path.
      6. Warns about openssl/err.h (external dep — must be installed separately).

    emit_line(text, cls) — optional callable to stream live log lines to the UI.
    Returns a list of action strings.
    """
    import xml.etree.ElementTree as ET
    import shutil

    actions = []

    def log(text, cls="dim"):
        actions.append(text)
        if emit_line:
            emit_line(text, cls)

    # ── 1. Parse ALL C1083 lines for missing Luau files ───────────────────────
    c1083_pat = re.compile(
        r"error C1083[^:]*:\s*[^:]*:\s*'([^']+)'",
        re.IGNORECASE,
    )

    luau_headers_missing  = set()   # .h/.hpp names (lowercase)
    luau_sources_missing  = set()   # .cpp names (lowercase) referenced in .vcxproj but absent
    xxhash_missing        = False
    openssl_missing       = False
    has_any_luau_error    = False

    for m in c1083_pat.finditer(last_build_output):
        raw   = m.group(1).replace("\\", "/")
        bname = os.path.basename(raw).lower()

        if bname == "xxhash.h":
            xxhash_missing  = True
            has_any_luau_error = True
            continue
        if "openssl" in raw.lower():
            openssl_missing = True
            continue
        if bname.endswith((".h", ".hpp")):
            is_luau = (
                bname in _LUAU_HEADER_DIRS
                or "luau" in raw.lower()
                or bname in ("lua.h", "luaconf.h", "lualib.h", "luacode.h",
                             "luacodegen.h", "lapi.h", "ldo.h", "lgc.h",
                             "lobject.h", "lstate.h", "lstring.h", "ltable.h",
                             "lmem.h", "ldebug.h", "lfunc.h", "lvm.h")
            )
            if is_luau:
                luau_headers_missing.add(bname)
                has_any_luau_error = True
        elif bname.endswith(".cpp"):
            if bname in _LUAU_SOURCE_MAP or "luau" in raw.lower():
                luau_sources_missing.add(bname)
                has_any_luau_error = True

    if not has_any_luau_error and not last_build_output:
        log("[INFO] No missing Luau files detected in last build output.")
        log("[INFO] Run a build first so Build Doctor can read the C1083 lines.")
        return actions

    if not has_any_luau_error:
        log("[INFO] No Luau-specific C1083 errors found — use FIX INCS for other missing headers.")
        return actions

    if luau_headers_missing:
        log(f"[INFO] Missing Luau headers: {', '.join(sorted(luau_headers_missing))}", "warn")
    if luau_sources_missing:
        log(f"[INFO] Missing Luau source files: {', '.join(sorted(luau_sources_missing))}", "warn")
    if xxhash_missing:
        log("[INFO] Missing: xxhash.h (Luau extern dependency)", "warn")
    if openssl_missing:
        log("[WARN] Missing: openssl/err.h — OpenSSL is NOT part of Luau.", "warn")
        log("[WARN] Install OpenSSL separately: https://slproweb.com/products/Win32OpenSSL.html", "warn")
        log("[WARN] Then add its include path to your .vcxproj manually (or use FIX INCS).", "warn")

    # ── 2. Find git root ──────────────────────────────────────────────────────
    git_root = _find_git_root(folder)
    if not git_root:
        log("[WARN] Project is not inside a git repository — submodule init unavailable.", "warn")
        log("[INFO] Will attempt direct clone into project folder instead.", "info")
        # Use the project folder itself as the "root" for cloning purposes
        git_root = folder
    else:
        log(f"[INFO] Git root: {git_root}")

    # ── 3. Find existing Luau submodule dir (may be empty) ───────────────────
    luau_search_dirs = []
    for base in (git_root, folder):
        for sub in ("Luau", "luau", os.path.join("deps", "Luau"),
                    os.path.join("vendor", "luau"), os.path.join("extern", "luau"),
                    os.path.join("third_party", "luau"), os.path.join("ext", "Luau")):
            luau_search_dirs.append(os.path.join(base, sub))

    luau_dir = None
    for candidate in luau_search_dirs:
        if os.path.isdir(candidate):
            luau_dir = candidate
            log(f"[INFO] Found Luau directory: {luau_dir}")
            break

    # Check .gitmodules (only meaningful if this is a real git repo)
    gitmodules_path = os.path.join(git_root, ".gitmodules")
    submodule_path_from_modules = None
    _has_real_git = os.path.exists(os.path.join(git_root, ".git"))
    if _has_real_git and os.path.exists(gitmodules_path):
        with open(gitmodules_path, encoding="utf-8", errors="ignore") as f:
            gm = f.read()
        for block in re.split(r"\[submodule", gm):
            if "luau" in block.lower():
                pm = re.search(r"path\s*=\s*(.+)", block)
                if pm:
                    submodule_path_from_modules = os.path.join(
                        git_root, pm.group(1).strip().replace("/", os.sep)
                    )
                    if luau_dir is None:
                        luau_dir = submodule_path_from_modules
                    log(f"[INFO] .gitmodules Luau path: {submodule_path_from_modules}")
                    break

    # ── 4a. Submodule exists → init + update (only if real git repo) ─────────
    if _has_real_git and luau_dir and (submodule_path_from_modules or
                     os.path.exists(os.path.join(git_root, ".gitmodules"))):
        luau_populated = (
            os.path.isdir(luau_dir) and
            any(
                f.lower() in ("cmakelists.txt", "readme.md", "luau.h")
                for f in (os.listdir(luau_dir) if os.path.isdir(luau_dir) else [])
            )
        )
        if not luau_populated:
            log("[*] Luau submodule found but not initialized — running git submodule update...", "info")
            rc, out = _run_git(
                ["submodule", "update", "--init", "--recursive", "--progress"],
                cwd=git_root,
            )
            for line in out.splitlines():
                if line.strip():
                    cls = "error" if "error" in line.lower() or "fatal" in line.lower() else "dim"
                    log(f"    {line.rstrip()}", cls)
            if rc != 0:
                log(f"[ERROR] git submodule update failed (exit {rc}).", "error")
                log("[INFO] Try running manually: git submodule update --init --recursive", "warn")
                return actions
            log("[+] Submodule initialized successfully.", "info")
        else:
            log("[INFO] Luau submodule directory already populated.")

    # ── 4b. No submodule → clone directly ────────────────────────────────────
    elif luau_dir is None:
        luau_dir = os.path.join(git_root, "Luau")
        log(f"[*] No Luau submodule found — cloning {_LUAU_REPO} into {luau_dir} ...", "info")
        rc, out = _run_git(
            ["clone", "--depth=1", "--recurse-submodules", _LUAU_REPO, luau_dir],
            cwd=git_root,
            timeout=600,
        )
        for line in out.splitlines():
            if line.strip():
                cls = "error" if "error" in line.lower() or "fatal" in line.lower() else "dim"
                log(f"    {line.rstrip()}", cls)
        if rc != 0:
            log(f"[ERROR] git clone failed (exit {rc}).", "error")
            log(f"[INFO] Clone manually: git clone --depth=1 {_LUAU_REPO} Luau", "warn")
            return actions
        log("[+] Luau cloned successfully.", "info")

    # ── 5. Determine include directories to inject ───────────────────────────
    inc_dirs_to_add = set()

    # ── 5a. ALWAYS add the full set of Luau sub-package include dirs ──────────
    # These must ALL be present together — Compiler/include headers do
    # #include "../Includes/Ast.h" style relative refs that require Ast/include
    # to be a sibling on the include path.
    _LUAU_ALWAYS_INCS = [
        "include",           # top-level flat includes
        "VM/include",        # lua.h, luaconf.h, lualib.h, luacode.h
        "Compiler/include",  # luacode.h, luau_compile, BytecodeBuilder.h
        "Ast/include",       # Ast.h, Location.h, Lexer.h, Parser.h  ← REQUIRED peer
        "Bytecode/include",  # BytecodeUtils.h, Bytecode.h
        "Common/include",    # Common.h, StringUtils.h
    ]
    for sub in _LUAU_ALWAYS_INCS:
        d = os.path.join(luau_dir, sub.replace("/", os.sep))
        if os.path.isdir(d):
            inc_dirs_to_add.add(d)

    # Add sub-package include dirs for missing headers
    for hname in luau_headers_missing:
        sub = _LUAU_HEADER_DIRS.get(hname)
        if sub:
            candidate = os.path.join(luau_dir, sub.replace("/", os.sep))
            if os.path.isdir(candidate):
                inc_dirs_to_add.add(candidate)
        flat = os.path.join(luau_dir, "include")
        if os.path.isdir(flat):
            inc_dirs_to_add.add(flat)

    # Always add all include/ dirs under the repo for completeness
    for rootdir, subdirs, _ in os.walk(luau_dir):
        subdirs[:] = [d for d in subdirs if d.lower() not in
                      (".git", "x64", "debug", "release", "build", "tests", "bench")]
        if os.path.basename(rootdir).lower() == "include":
            inc_dirs_to_add.add(rootdir)

    # xxhash: find extern/xxhash inside Luau repo
    if xxhash_missing:
        for xd in _XXHASH_DIRS:
            xp = os.path.join(luau_dir, xd.replace("/", os.sep))
            if os.path.isdir(xp):
                inc_dirs_to_add.add(xp)
                log(f"[INFO] Found xxhash at: {xp}", "info")
                break
        else:
            log("[WARN] xxhash directory not found inside Luau repo — check extern/xxhash.", "warn")

    if not inc_dirs_to_add:
        log(f"[WARN] Could not find any include/ dirs under {luau_dir}.", "warn")
        return actions

    # ── 5b. Also find project-local Includes/ dirs (handles ../Includes/ style) ──
    # Walk the project folder for any directory named "Include", "Includes",
    # "inc", or "headers" and inject those too — catches hand-rolled include layouts.
    _LOCAL_INC_NAMES = {"include", "includes", "inc", "headers", "header"}
    for rootdir, subdirs, _ in os.walk(folder):
        subdirs[:] = [d for d in subdirs if d.lower() not in
                      (".git", ".vs", "x64", "x86", "debug", "release",
                       "build", "__pycache__", "luau")]
        bn = os.path.basename(rootdir).lower()
        if bn in _LOCAL_INC_NAMES:
            inc_dirs_to_add.add(rootdir)
            log(f"[INFO] Found local include dir: {rootdir}")

    for d in sorted(inc_dirs_to_add):
        log(f"[INFO] Will inject include path: {d}")

    # ── 6. Copy missing .cpp source files into project's src/Luau/ ───────────
    # IMPORTANT: Also copy the matching headers from the SAME clone into the
    # project's own Compiler/include/Luau/ so headers and .cpp are always the
    # same commit. Version mismatch between a stale header and a freshly cloned
    # .cpp causes C2051 (enum not constant), C2065 (undeclared members), and
    # C4003 (LUAU_FASTFLAGVARIABLE wrong arg count) — all seen in practice.
    copied_sources = []   # list of (dest_abs_path, rel_from_proj_dir)

    if luau_sources_missing:
        # Determine target directory: look for an existing src\Luau or src\luau,
        # or fall back to creating one next to the .vcxproj
        target_src_dir = None
        for rootdir, dirs, files in os.walk(folder):
            bn = os.path.basename(rootdir).lower()
            parent_bn = os.path.basename(os.path.dirname(rootdir)).lower()
            if bn == "luau" and parent_bn in ("src", "source", "sources"):
                target_src_dir = rootdir
                break
        if target_src_dir is None:
            # Create <project>/src/Luau/
            target_src_dir = os.path.join(folder, "src", "Luau")

        os.makedirs(target_src_dir, exist_ok=True)
        log(f"[INFO] Target source directory: {target_src_dir}", "info")

        for src_name in sorted(luau_sources_missing):
            dest = os.path.join(target_src_dir, src_name)
            if os.path.exists(dest):
                log(f"[OK] {src_name}: already present at {dest}")
                continue

            # Try to find the file in the Luau repo
            primary = _LUAU_SOURCE_MAP.get(src_name, "")
            alts    = _LUAU_SOURCE_ALT.get(src_name, [])
            src_abs = _find_file_in_repo(luau_dir, src_name, primary, alts)

            if src_abs:
                try:
                    shutil.copy2(src_abs, dest)
                    rel_to_folder = os.path.relpath(dest, folder)
                    copied_sources.append((dest, rel_to_folder))
                    log(f"[FIXED-SRC] Copied {src_name} → {rel_to_folder}", "info")
                except OSError as exc:
                    log(f"[ERROR] Could not copy {src_name}: {exc}", "error")
            else:
                log(f"[WARN] {src_name} not found in Luau repo — may need manual copy.", "warn")

    # ── 6b. Sync Luau headers into project's Compiler/include/Luau/ ──────────
    # If we copied any .cpp files, also copy the headers from the SAME clone
    # so the project is guaranteed to use matching header/source versions.
    # This prevents C2051 / C2065 / C4003 version-mismatch errors.
    if luau_sources_missing or luau_headers_missing:
        log("[*] Syncing Luau headers from cloned repo into project...", "info")
        # Map: sub-package include dir in repo → dest dir in project
        # We place them under <folder>/Compiler/include/Luau/ mirroring the
        # standard Luau flat layout expected by BytecodeBuilder.h etc.
        _HDR_SYNC_SUBDIRS = [
            ("Compiler/include/Luau", os.path.join(folder, "Compiler", "include", "Luau")),
            ("Ast/include/Luau",      os.path.join(folder, "Ast",      "include", "Luau")),
            ("VM/include",            os.path.join(folder, "VM",       "include")),
            ("Bytecode/include/Luau", os.path.join(folder, "Bytecode", "include", "Luau")),
            ("Common/include/Luau",   os.path.join(folder, "Common",   "include", "Luau")),
        ]
        for repo_sub, dest_dir in _HDR_SYNC_SUBDIRS:
            repo_src_dir = os.path.join(luau_dir, repo_sub.replace("/", os.sep))
            if not os.path.isdir(repo_src_dir):
                continue
            os.makedirs(dest_dir, exist_ok=True)
            for hfile in os.listdir(repo_src_dir):
                if not hfile.lower().endswith((".h", ".hpp")):
                    continue
                src_h  = os.path.join(repo_src_dir, hfile)
                dest_h = os.path.join(dest_dir, hfile)
                try:
                    # Always overwrite — ensure version consistency
                    shutil.copy2(src_h, dest_h)
                    log(f"[FIXED-HDR] Synced {hfile} → {os.path.relpath(dest_h, folder)}", "info")
                except OSError as exc:
                    log(f"[WARN] Could not sync header {hfile}: {exc}", "warn")
        # After syncing, also add the project-local header dirs to inc_dirs_to_add
        for _, dest_dir in _HDR_SYNC_SUBDIRS:
            parent = os.path.dirname(dest_dir)  # e.g. Compiler/include
            if os.path.isdir(parent):
                inc_dirs_to_add.add(parent)
            if os.path.isdir(dest_dir):
                inc_dirs_to_add.add(dest_dir)
    all_vcxproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    for vcxproj_path in all_vcxproj:
        proj_dir = os.path.dirname(vcxproj_path)
        fname    = os.path.basename(vcxproj_path)
        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            log(f"[SKIP] {fname}: XML parse error — {exc}", "warn")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def tag(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        proj_changed = False

        # 7a. Inject include directories ──────────────────────────────────────
        existing_inc = set()
        for el in root.iter(tag("AdditionalIncludeDirectories")):
            for part in re.split(r"[;,]", el.text or ""):
                part = part.strip()
                if part and "%" not in part:
                    existing_inc.add(os.path.normpath(os.path.join(proj_dir, part)).lower())

        new_rel = []
        for inc_abs in sorted(inc_dirs_to_add):
            norm_abs = os.path.normpath(inc_abs).lower()
            if norm_abs not in existing_inc:
                try:
                    rel = os.path.relpath(inc_abs, proj_dir)
                except ValueError:
                    rel = inc_abs
                # Also guard against the relative form already being present
                norm_rel = os.path.normpath(os.path.join(proj_dir, rel)).lower()
                if norm_rel not in existing_inc:
                    new_rel.append(rel)
                    existing_inc.add(norm_rel)   # prevent adding the same dir twice

        if new_rel:
            new_str = ";".join(new_rel) + ";%(AdditionalIncludeDirectories)"
            updated = 0
            for idg in root.iter(tag("ItemDefinitionGroup")):
                for clc in idg.iter(tag("ClCompile")):
                    aid = clc.find(tag("AdditionalIncludeDirectories"))
                    if aid is not None:
                        existing_text = (aid.text or "").replace(
                            ";%(AdditionalIncludeDirectories)", ""
                        ).rstrip(";")
                        parts = [p for p in existing_text.split(";") if p.strip()]
                        # Build a normalised set of what's already listed
                        already_norm = {
                            os.path.normpath(os.path.join(proj_dir, p)).lower()
                            for p in parts if p.strip()
                        }
                        for rel in new_rel:
                            norm = os.path.normpath(os.path.join(proj_dir, rel)).lower()
                            if norm not in already_norm:
                                parts.append(rel)
                                already_norm.add(norm)
                        aid.text = ";".join(parts) + ";%(AdditionalIncludeDirectories)"
                    else:
                        el      = ET.SubElement(clc, tag("AdditionalIncludeDirectories"))
                        el.text = new_str
                    updated += 1
            if updated == 0:
                idg = ET.SubElement(root, tag("ItemDefinitionGroup"))
                clc = ET.SubElement(idg, tag("ClCompile"))
                el  = ET.SubElement(clc, tag("AdditionalIncludeDirectories"))
                el.text = new_str
            proj_changed = True
            log(f"[FIXED-LUAU] {fname}: injected {len(new_rel)} include path(s)", "info")
        else:
            log(f"[OK] {fname}: Luau include paths already present.")

        # 7b. Inject ClCompile entries for newly copied .cpp files ────────────
        if copied_sources:
            # Collect already-referenced .cpp files
            existing_compile = set()
            for el in root.iter(tag("ClCompile")):
                inc_attr = el.attrib.get("Include", "")
                if inc_attr:
                    existing_compile.add(
                        os.path.normpath(os.path.join(proj_dir, inc_attr.replace("/", os.sep))).lower()
                    )

            srcs_to_add = []
            for dest_abs, rel_to_folder in copied_sources:
                abs_norm = os.path.normpath(dest_abs).lower()
                if abs_norm not in existing_compile:
                    try:
                        rel_from_proj = os.path.relpath(dest_abs, proj_dir)
                    except ValueError:
                        rel_from_proj = dest_abs
                    srcs_to_add.append(rel_from_proj)

            if srcs_to_add:
                # Find or create an ItemGroup for source files
                src_ig = None
                for ig in root.iter(tag("ItemGroup")):
                    if ig.find(tag("ClCompile")) is not None:
                        src_ig = ig
                        break
                if src_ig is None:
                    src_ig = ET.SubElement(root, tag("ItemGroup"))

                for rel_src in srcs_to_add:
                    el = ET.SubElement(src_ig, tag("ClCompile"))
                    el.attrib["Include"] = rel_src
                    log(f"[FIXED-SRC] {fname}: added ClCompile → {rel_src}", "info")

                proj_changed = True

        if proj_changed:
            if xmlns:
                ET.register_namespace("", xmlns)
            tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)

    if openssl_missing:
        log("", "dim")
        log("[!] OpenSSL (openssl/err.h) still requires manual install:", "warn")
        log("    → https://slproweb.com/products/Win32OpenSSL.html", "warn")
        log("    → After installing, add its include path via FIX INCS or Settings.", "warn")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 8: BOM Cleanup in .cs files
# ─────────────────────────────────────────────

def fix_cs_bom(folder):
    """
    Strips UTF-8 BOM (\\xef\\xbb\\xbf) from the beginning of .cs files.
    A BOM in the middle of a C# compilation unit can cause CS1513 or
    'unexpected character' errors in some SDK/CLI scenarios.
    Returns a list of action strings.
    """
    actions    = []
    BOM        = "\ufeff"
    cs_found   = 0

    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if not fname.lower().endswith(".cs"):
                continue
            full    = os.path.join(rootdir, fname)
            rel     = os.path.relpath(full, folder).replace("\\", "/")
            cs_found += 1
            try:
                with open(full, "r", encoding="utf-8-sig", errors="ignore") as f:
                    content = f.read()
                # utf-8-sig automatically strips BOM on read
                # Check if raw bytes start with BOM
                with open(full, "rb") as fb:
                    raw_start = fb.read(3)
                if raw_start == b"\xef\xbb\xbf":
                    with open(full, "w", encoding="utf-8") as f:
                        f.write(content)
                    actions.append(f"[FIXED-BOM] {rel}: removed UTF-8 BOM.")
            except OSError as exc:
                actions.append(f"[ERROR] {rel}: {exc}")

    if cs_found == 0:
        actions.append("No .cs files found.")
    elif not any(a.startswith("[FIXED-BOM]") for a in actions):
        actions.append(f"[OK] Checked {cs_found} .cs file(s): no BOM issues found.")

    return actions


# ─────────────────────────────────────────────
# Framework Consistency Check
# ─────────────────────────────────────────────

def check_framework_consistency(folder):
    """
    Scans .csproj files and extracts <TargetFramework> / <TargetFrameworks>.
    Returns {"frameworks": {name:[fw,...]}, "mixed": bool, "warnings": [str]}
    """
    result = {"frameworks": {}, "mixed": False, "warnings": []}

    all_csproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".csproj"):
                all_csproj.append(os.path.join(rootdir, fname))

    if not all_csproj:
        return result

    fw_set = set()
    for cp in all_csproj:
        fname = os.path.basename(cp)
        try:
            tree, root, xmlns = _parse_csproj(cp)
        except Exception:
            continue

        frameworks = []
        for tag_name in ("TargetFramework", "TargetFrameworks"):
            for el in root.iter(_tag(xmlns, tag_name)):
                if el.text:
                    for fw in el.text.split(";"):
                        fw = fw.strip()
                        if fw:
                            frameworks.append(fw)
                            fw_set.add(fw)

        if frameworks:
            result["frameworks"][fname] = frameworks

    legacy = {f for f in fw_set if re.match(r"^net[1-4]\d*$", f, re.IGNORECASE)}
    modern = {f for f in fw_set if re.match(
        r"^net[5-9]|^net\d{2}|netcoreapp|netstandard", f, re.IGNORECASE)}

    if legacy and modern:
        result["mixed"] = True
        result["warnings"].append(
            f"Mixed target frameworks: legacy ({', '.join(sorted(legacy))}) "
            f"vs modern ({', '.join(sorted(modern))}). This can cause "
            "reference and runtime compatibility errors."
        )
    elif len(fw_set) > 1:
        result["warnings"].append(
            f"Multiple target frameworks across projects: {', '.join(sorted(fw_set))}. "
            "Verify all ProjectReferences are compatible."
        )

    return result


# ─────────────────────────────────────────────
# NuGet / dotnet restore
# ─────────────────────────────────────────────

def _run_dotnet_restore_cmd(folder):
    """
    Runs 'dotnet restore' in the given folder.
    Returns {"ok": bool, "output": str, "returncode": int}
    """
    try:
        proc = subprocess.run(
            ["dotnet", "restore"],
            cwd=folder,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore",
            timeout=180
        )
        combined = (proc.stdout or "") + (proc.stderr or "")
        return {"ok": proc.returncode == 0, "output": combined, "returncode": proc.returncode}
    except FileNotFoundError:
        return {
            "ok": False,
            "output": "'dotnet' is not recognized — install the .NET SDK and add it to PATH.",
            "returncode": -1
        }
    except subprocess.TimeoutExpired:
        return {
            "ok": False,
            "output": "dotnet restore timed out after 180 seconds.",
            "returncode": -1
        }
    except Exception as exc:
        return {"ok": False, "output": str(exc), "returncode": -1}


# ─────────────────────────────────────────────
# Fix-All orchestrator (C# projects)
# ─────────────────────────────────────────────

def fix_all_cs(folder):
    """
    Runs all C# / csproj auto-fix passes in order:
      Pass 1 & 2 — Dead Compile refs + Missing ProjectReferences
      Pass 3     — Duplicate references + Empty ItemGroups
      Pass 4     — Missing AssemblyName / RootNamespace
      Pass 5     — C# BOM cleanup
    Returns a combined action list.
    """
    result = []
    result.append("=== Pass 1 & 2: Dead Compile Refs + Missing ProjectRefs ===")
    result.extend(fix_missing_cs_files(folder))
    result.append("")
    result.append("=== Pass 3: Duplicate References + Empty ItemGroups ===")
    result.extend(fix_duplicate_refs(folder))
    result.append("")
    result.append("=== Pass 4: AssemblyName / RootNamespace ===")
    result.extend(fix_assembly_metadata(folder))
    result.append("")
    result.append("=== Pass 5: UTF-8 BOM Cleanup ===")
    result.extend(fix_cs_bom(folder))
    return result


# ─────────────────────────────────────────────
# Auto-Fix Pass 9: Missing ClCompile / ClInclude in .vcxproj
# ─────────────────────────────────────────────

def fix_vcxproj_missing_items(folder):
    """
    Scans every .vcxproj under `folder` and compares the files it references
    against the files that physically exist on disk.

    For EACH .vcxproj this pass will:
      A) Find every .cpp / .c file on disk (under the project folder) that is
         NOT already listed as a <ClCompile Include="..."/> entry — and add it.
      B) Find every .h / .hpp file on disk that is NOT already listed as a
         <ClInclude Include="..."/> entry — and add it.
      C) Remove any <ClCompile> or <ClInclude> entries whose path resolves to a
         file that no longer exists on disk (dead references).

    Skips output/cache directories (x64, x86, Debug, Release, .vs, .git,
    __pycache__, RelWithDebInfo, MinSizeRel, build, CMakeFiles).

    Returns a list of human-readable action strings.
    """
    import xml.etree.ElementTree as ET

    actions = []

    # Directories that are build-output or tooling artefacts — never source
    _SKIP_DIRS = {
        "x64", "x86", "debug", "release", "relwithdebinfo", "minsizerel",
        ".vs", ".git", "__pycache__", "build", "cmake_install",
        "cmakefiles", "ipch", ".cache",
    }

    all_vcxproj = []
    for rootdir, dirs, files in os.walk(folder):
        dirs[:] = [d for d in dirs if d.lower() not in _SKIP_DIRS]
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    if not all_vcxproj:
        actions.append("[SKIP] No .vcxproj files found under the selected folder.")
        return actions

    for vcxproj_path in all_vcxproj:
        proj_dir = os.path.dirname(vcxproj_path)
        fname    = os.path.basename(vcxproj_path)

        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def _tag(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        def _strip(tag):
            return re.sub(r"^\{.*?\}", "", tag)

        # ── Collect what the project already references ───────────────────────
        # Normalised absolute paths already in the project file
        existing_compile  = {}   # norm_abs_lower -> element
        existing_include  = {}   # norm_abs_lower -> element
        dead_compile      = []   # (parent_ig, element, display_path)
        dead_include      = []

        for ig in root.iter(_tag("ItemGroup")):
            for child in list(ig):
                tag_local = _strip(child.tag)
                inc_attr  = child.attrib.get("Include", "")
                if not inc_attr:
                    continue
                abs_path  = os.path.normpath(
                    os.path.join(proj_dir, inc_attr.replace("/", os.sep))
                )
                norm      = abs_path.lower()
                if tag_local == "ClCompile":
                    if os.path.isfile(abs_path):
                        existing_compile[norm] = child
                    else:
                        dead_compile.append((ig, child, inc_attr))
                elif tag_local == "ClInclude":
                    if os.path.isfile(abs_path):
                        existing_include[norm] = child
                    else:
                        dead_include.append((ig, child, inc_attr))

        # ── Walk disk for all source/header files ─────────────────────────────
        disk_sources  = {}   # norm_abs_lower -> abs_path
        disk_headers  = {}

        for rootdir2, dirs2, files2 in os.walk(proj_dir):
            dirs2[:] = [d for d in dirs2 if d.lower() not in _SKIP_DIRS]
            for f in files2:
                abs_f = os.path.join(rootdir2, f)
                norm  = abs_f.lower()
                lo    = f.lower()
                if lo.endswith((".cpp", ".c", ".cxx", ".cc")):
                    disk_sources[norm] = abs_f
                elif lo.endswith((".h", ".hpp", ".hxx", ".hh")):
                    disk_headers[norm] = abs_f

        # ── Compute what needs to be added ────────────────────────────────────
        missing_sources = {
            n: p for n, p in disk_sources.items()
            if n not in existing_compile
        }
        missing_headers = {
            n: p for n, p in disk_headers.items()
            if n not in existing_include
        }

        changed = False

        # ── A) Remove dead <ClCompile> entries ────────────────────────────────
        for ig, child, disp in dead_compile:
            ig.remove(child)
            changed = True
            actions.append(f"[FIXED-DEAD] {fname}: removed dead <ClCompile Include=\"{disp}\" />")

        # ── B) Remove dead <ClInclude> entries ────────────────────────────────
        for ig, child, disp in dead_include:
            ig.remove(child)
            changed = True
            actions.append(f"[FIXED-DEAD] {fname}: removed dead <ClInclude Include=\"{disp}\" />")

        # ── C) Add missing <ClCompile> entries ────────────────────────────────
        if missing_sources:
            # Find existing ClCompile ItemGroup or create one
            src_ig = None
            for ig in root.iter(_tag("ItemGroup")):
                for child in ig:
                    if _strip(child.tag) == "ClCompile":
                        src_ig = ig
                        break
                if src_ig is not None:
                    break
            if src_ig is None:
                src_ig = ET.SubElement(root, _tag("ItemGroup"))

            for norm, abs_p in sorted(missing_sources.items()):
                try:
                    rel = os.path.relpath(abs_p, proj_dir)
                except ValueError:
                    rel = abs_p   # different drive — keep absolute
                el = ET.SubElement(src_ig, _tag("ClCompile"))
                el.set("Include", rel)
                changed = True
                actions.append(f"[FIXED-ADD] {fname}: added <ClCompile Include=\"{rel}\" />")

        # ── D) Add missing <ClInclude> entries ────────────────────────────────
        if missing_headers:
            # Find existing ClInclude ItemGroup or create one
            hdr_ig = None
            for ig in root.iter(_tag("ItemGroup")):
                for child in ig:
                    if _strip(child.tag) == "ClInclude":
                        hdr_ig = ig
                        break
                if hdr_ig is not None:
                    break
            if hdr_ig is None:
                hdr_ig = ET.SubElement(root, _tag("ItemGroup"))

            for norm, abs_p in sorted(missing_headers.items()):
                try:
                    rel = os.path.relpath(abs_p, proj_dir)
                except ValueError:
                    rel = abs_p
                el = ET.SubElement(hdr_ig, _tag("ClInclude"))
                el.set("Include", rel)
                changed = True
                actions.append(f"[FIXED-ADD] {fname}: added <ClInclude Include=\"{rel}\" />")

        # ── Write back if modified ────────────────────────────────────────────
        if changed:
            if xmlns:
                ET.register_namespace("", xmlns)
            tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)
        else:
            total = len(existing_compile) + len(existing_include)
            actions.append(
                f"[OK] {fname}: all {total} source/header reference(s) already present and valid."
            )

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 10: Missing .lib Files (LNK2001/LNK2019/LNK1181)
# ─────────────────────────────────────────────

def fix_missing_libs(folder, last_build_output=""):
    """
    Scans build output for LNK2001/LNK2019/LNK1181 unresolved symbol errors,
    attempts to find matching .lib files anywhere in the project tree or common
    SDK locations, and injects them into AdditionalDependencies / AdditionalLibraryDirectories
    in every .vcxproj found.

    Also does a blanket scan: any .lib found under the project folder whose
    directory is not already in the vcxproj lib paths gets added.

    Returns a list of action strings.
    """
    import xml.etree.ElementTree as ET

    actions = []

    # ── Step 1: extract referenced symbol names from LNK errors ──────────────
    # LNK2001/LNK2019: "unresolved external symbol __imp_SomeFunc"
    # LNK1181: "cannot open input file 'foo.lib'"
    lnk_sym_pat   = re.compile(r"(?:LNK2001|LNK2019)[^\n]*?symbol\s+\"([^\"]+)\"", re.IGNORECASE)
    lnk1181_pat   = re.compile(r"LNK1181[^\n]*?'([^']+\.lib)'", re.IGNORECASE)
    lnk_open_pat  = re.compile(r"cannot open file[^\n]*?'([^']+\.lib)'", re.IGNORECASE)

    explicit_libs = set()   # .lib filenames named directly in errors
    for m in lnk1181_pat.finditer(last_build_output):
        explicit_libs.add(os.path.basename(m.group(1)).lower())
    for m in lnk_open_pat.finditer(last_build_output):
        explicit_libs.add(os.path.basename(m.group(1)).lower())

    has_lnk = bool(
        re.search(r"LNK2001|LNK2019|LNK1181|LNK1120|LNK1104", last_build_output, re.IGNORECASE)
    )

    if not has_lnk and not last_build_output:
        actions.append("[INFO] No LNK errors detected — running blanket .lib scan instead.")
    elif not has_lnk:
        actions.append("[INFO] No LNK errors found in last build output.")
        return actions

    if explicit_libs:
        actions.append(f"[INFO] Libs named in errors: {', '.join(sorted(explicit_libs))}")

    # ── Step 2: find all .vcxproj ────────────────────────────────────────────
    all_vcxproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    if not all_vcxproj:
        actions.append("[SKIP] No .vcxproj files found.")
        return actions

    # ── Step 3: build map of all .lib files in the project tree ──────────────
    _SKIP_DIRS = {"x64", "x86", "debug", "release", ".git", ".vs",
                  "__pycache__", "relwithdebinfo", "minsizerel"}
    lib_dir_map  = {}   # libname.lower() -> set of abs dir paths
    for rootdir, dirs, files in os.walk(folder):
        dirs[:] = [d for d in dirs if d.lower() not in _SKIP_DIRS]
        for f in files:
            if f.lower().endswith(".lib"):
                lib_dir_map.setdefault(f.lower(), set()).add(rootdir)

    # Also search common Windows SDK / VC lib paths
    sdk_lib_roots = []
    for env in ("ProgramFiles", "ProgramFiles(x86)"):
        pf = os.environ.get(env, "")
        if pf:
            sdk_lib_roots += [
                os.path.join(pf, "Windows Kits", "10", "Lib"),
                os.path.join(pf, "Microsoft Visual Studio"),
            ]
    for root in sdk_lib_roots:
        if not os.path.isdir(root):
            continue
        for rootdir, dirs, files in os.walk(root):
            dirs[:] = [d for d in dirs if d.lower() not in _SKIP_DIRS]
            for f in files:
                if f.lower().endswith(".lib"):
                    lib_dir_map.setdefault(f.lower(), set()).add(rootdir)

    # ── Step 4: resolve directories to inject ────────────────────────────────
    needed_lib_dirs  = set()
    needed_lib_names = set()

    if explicit_libs:
        for lname in explicit_libs:
            found = lib_dir_map.get(lname, set())
            if found:
                for d in found:
                    needed_lib_dirs.add(d)
                    needed_lib_names.add(lname)
                    actions.append(f"[FOUND] '{lname}' → {d}")
            else:
                actions.append(f"[WARN] '{lname}' not found in project tree or SDK paths.")
    else:
        # Blanket: collect every dir that has .lib files under the project folder
        for dirs in lib_dir_map.values():
            for d in dirs:
                if d.startswith(folder):
                    needed_lib_dirs.add(d)

    if not needed_lib_dirs:
        actions.append("[OK] No new lib directories to inject.")
        return actions

    # ── Step 5: patch each .vcxproj ──────────────────────────────────────────
    for vcxproj_path in all_vcxproj:
        proj_dir = os.path.dirname(vcxproj_path)
        fname    = os.path.basename(vcxproj_path)

        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def _t(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        # Gather existing lib dirs
        existing_lib_dirs = set()
        for el in root.iter(_t("AdditionalLibraryDirectories")):
            for part in re.split(r"[;,]", el.text or ""):
                part = part.strip()
                if part and "%" not in part:
                    existing_lib_dirs.add(
                        os.path.normpath(os.path.join(proj_dir, part)).lower()
                    )

        new_lib_rels = []
        for d in sorted(needed_lib_dirs):
            norm = os.path.normpath(d).lower()
            if norm not in existing_lib_dirs:
                try:
                    rel = os.path.relpath(d, proj_dir)
                except ValueError:
                    rel = d
                new_lib_rels.append(rel)
                existing_lib_dirs.add(norm)

        # Gather existing AdditionalDependencies
        existing_dep_names = set()
        for el in root.iter(_t("AdditionalDependencies")):
            for part in re.split(r"[;,]", el.text or ""):
                existing_dep_names.add(part.strip().lower())

        new_dep_names = [
            n for n in sorted(needed_lib_names)
            if n.lower() not in existing_dep_names
        ]

        changed = False

        for idg in root.iter(_t("ItemDefinitionGroup")):
            link_el = idg.find(_t("Link"))
            if link_el is None:
                link_el = ET.SubElement(idg, _t("Link"))

            if new_lib_rels:
                ald = link_el.find(_t("AdditionalLibraryDirectories"))
                if ald is None:
                    ald = ET.SubElement(link_el, _t("AdditionalLibraryDirectories"))
                    ald.text = ""
                existing_text = (ald.text or "").replace(
                    ";%(AdditionalLibraryDirectories)", ""
                ).rstrip(";")
                parts = [p for p in existing_text.split(";") if p.strip()]
                for rel in new_lib_rels:
                    norm = os.path.normpath(os.path.join(proj_dir, rel)).lower()
                    if norm not in {os.path.normpath(os.path.join(proj_dir, p)).lower() for p in parts}:
                        parts.append(rel)
                ald.text = ";".join(parts) + ";%(AdditionalLibraryDirectories)"
                changed = True

            if new_dep_names:
                ad = link_el.find(_t("AdditionalDependencies"))
                if ad is None:
                    ad = ET.SubElement(link_el, _t("AdditionalDependencies"))
                    ad.text = ""
                existing_text = (ad.text or "").replace(
                    ";%(AdditionalDependencies)", ""
                ).rstrip(";")
                parts = [p for p in existing_text.split(";") if p.strip()]
                for dep in new_dep_names:
                    if dep not in {p.lower() for p in parts}:
                        parts.append(dep)
                ad.text = ";".join(parts) + ";%(AdditionalDependencies)"
                changed = True

        if changed:
            if xmlns:
                ET.register_namespace("", xmlns)
            tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)
            if new_lib_rels:
                actions.append(f"[FIXED-LIB] {fname}: injected {len(new_lib_rels)} lib path(s) → {', '.join(new_lib_rels)}")
            if new_dep_names:
                actions.append(f"[FIXED-LIB] {fname}: added {len(new_dep_names)} lib(s) to AdditionalDependencies → {', '.join(new_dep_names)}")
        else:
            actions.append(f"[OK] {fname}: all required lib paths already present.")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 11: Precompiled Header (PCH) Auto-Stub
# ─────────────────────────────────────────────

def fix_pch(folder, last_build_output=""):
    """
    Handles C1010: 'unexpected end of file while looking for precompiled header'.

    Strategy A — If the project has UsePrecompiledHeader=Use in its .vcxproj but
                  the pch.h / stdafx.h file doesn't exist, creates a minimal stub.
    Strategy B — If no PCH is configured but C1010 fires anyway, DISABLES PCH in
                  the .vcxproj (sets PrecompiledHeader to NotUsing).

    Returns a list of action strings.
    """
    import xml.etree.ElementTree as ET

    actions = []

    has_c1010 = bool(re.search(r"error C1010", last_build_output, re.IGNORECASE))
    if not has_c1010 and last_build_output:
        actions.append("[INFO] No C1010 errors detected — PCH looks fine.")
        return actions

    all_vcxproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    if not all_vcxproj:
        actions.append("[SKIP] No .vcxproj files found.")
        return actions

    for vcxproj_path in all_vcxproj:
        proj_dir = os.path.dirname(vcxproj_path)
        fname    = os.path.basename(vcxproj_path)

        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def _t(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        changed = False

        # Find PrecompiledHeader settings
        pch_use   = None   # element with Use/Create/NotUsing
        pch_file  = None   # element with pch header filename
        pch_filename = "pch.h"

        for idg in root.iter(_t("ItemDefinitionGroup")):
            clc = idg.find(_t("ClCompile"))
            if clc is not None:
                el = clc.find(_t("PrecompiledHeader"))
                if el is not None:
                    pch_use = el
                el2 = clc.find(_t("PrecompiledHeaderFile"))
                if el2 is not None and el2.text:
                    pch_file = el2
                    pch_filename = el2.text.strip()

        pch_abs = os.path.join(proj_dir, pch_filename)

        if pch_use is not None and (pch_use.text or "").strip().lower() == "use":
            # PCH is configured as "Use" — ensure the header file exists
            if not os.path.exists(pch_abs):
                stub_content = (
                    "#pragma once\n"
                    "// Auto-generated precompiled header stub by Build Doctor\n"
                    "// Add your commonly-used headers here.\n\n"
                    "#include <windows.h>\n"
                    "#include <string>\n"
                    "#include <vector>\n"
                    "#include <memory>\n"
                )
                try:
                    with open(pch_abs, "w", encoding="utf-8") as f:
                        f.write(stub_content)
                    actions.append(f"[FIXED-PCH] Created stub PCH file: {pch_filename}")
                    changed = True
                except OSError as exc:
                    actions.append(f"[ERROR] Could not create {pch_filename}: {exc}")
            else:
                actions.append(f"[OK] {fname}: PCH file '{pch_filename}' already exists.")

            # ── BUG FIX: Strategy A was missing this step ──────────────────────
            # C1010 fires when .cpp files don't have #include "pch.h" as their
            # FIRST line. Creating the stub alone is not enough — we must also
            # inject the include into every source file that is missing it.
            include_line = f'#include "{pch_filename}"\n'
            include_pat  = re.compile(
                r'^\s*#\s*include\s*["\']' + re.escape(pch_filename) + r'["\']',
                re.IGNORECASE
            )
            for rootdir2, _, src_files in os.walk(proj_dir):
                for src_fname in src_files:
                    if not src_fname.lower().endswith((".cpp", ".cxx", ".cc")):
                        continue
                    src_path = os.path.join(rootdir2, src_fname)
                    try:
                        with open(src_path, "r", encoding="utf-8", errors="ignore") as sf:
                            src_content = sf.read()
                        # Skip if already has the include anywhere in the first 20 lines
                        first_lines = "\n".join(src_content.splitlines()[:20])
                        if include_pat.search(first_lines):
                            continue
                        # Strip UTF-8 BOM before prepending
                        if src_content.startswith("\ufeff"):
                            src_content = src_content[1:]
                        with open(src_path, "w", encoding="utf-8") as sf:
                            sf.write(include_line + src_content)
                        rel_src = os.path.relpath(src_path, proj_dir).replace("\\", "/")
                        actions.append(f"[FIXED-PCH] Injected #include \"{pch_filename}\" into: {rel_src}")
                        changed = True
                    except OSError as exc:
                        rel_src = os.path.relpath(src_path, proj_dir).replace("\\", "/")
                        actions.append(f"[ERROR] Could not patch {rel_src}: {exc}")

        elif pch_use is not None and (pch_use.text or "").strip().lower() in ("", "notusing"):
            actions.append(f"[OK] {fname}: PCH already disabled (NotUsing).")
        else:
            # No PCH config at all, or C1010 fired — disable PCH globally in .vcxproj
            for idg in root.iter(_t("ItemDefinitionGroup")):
                clc = idg.find(_t("ClCompile"))
                if clc is not None:
                    el = clc.find(_t("PrecompiledHeader"))
                    if el is None:
                        el = ET.SubElement(clc, _t("PrecompiledHeader"))
                    el.text = "NotUsing"
                    changed = True

            if changed:
                actions.append(f"[FIXED-PCH] {fname}: disabled PCH (set NotUsing on all ClCompile groups).")
            else:
                actions.append(f"[OK] {fname}: no PCH configuration found — no change needed.")

        if changed:
            if xmlns:
                ET.register_namespace("", xmlns)
            tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 11b: WinAPI SIZE_T type fix (C2664)
# ─────────────────────────────────────────────

def fix_winapi_size_t(folder, last_build_output=""):
    """
    Fixes C2664: cannot convert 'DWORD *' to 'SIZE_T *' for the
    lpNumberOfBytesWritten / lpNumberOfBytesRead parameter of
    WriteProcessMemory and ReadProcessMemory.

    This is the canonical 32-bit → x64 porting issue in EyeStep and
    similar old executor libraries: the variables used as the last arg
    were declared as DWORD but the x64 Windows SDK now expects SIZE_T.

    Strategy:
    1. Parse affected filenames from build output (C2664 lines).
    2. In each file find every call to Write/ReadProcessMemory and
       extract the variable name from the &var 5th argument.
    3. Change all DWORD declarations of those variables to SIZE_T.
    4. Also fixes the common local pattern  "DWORD bytesWritten/bytesRead"
       even if the build output parser missed the file.
    """
    actions = []

    # Only run when the relevant error is present
    trigger_pat = re.compile(
        r"error C2664.*(?:WriteProcessMemory|ReadProcessMemory).*DWORD.*SIZE_T"
        r"|error C2664.*(?:WriteProcessMemory|ReadProcessMemory).*SIZE_T.*DWORD",
        re.IGNORECASE,
    )
    if last_build_output and not trigger_pat.search(last_build_output):
        actions.append("[INFO] No C2664 WriteProcessMemory/ReadProcessMemory errors — skipping.")
        return actions

    # --- collect affected source files from error output -----------------
    # Match lines like:  C:\...\eyestep_utility.cpp(45,103): error C2664 ...
    file_line_pat = re.compile(
        r"([A-Za-z]:[^\(\[\]]+\.cpp)\(\d+",
        re.IGNORECASE,
    )
    affected = set()
    for m in file_line_pat.finditer(last_build_output or ""):
        p = m.group(1).strip()
        if os.path.isfile(p):
            affected.add(p)

    # Fallback: walk the folder and inspect every .cpp
    if not affected:
        for rootdir, _, files in os.walk(folder):
            for fname in files:
                if fname.lower().endswith((".cpp", ".cxx", ".cc")):
                    affected.add(os.path.join(rootdir, fname))

    # --- regex to find the 5th argument variable name --------------------
    # WriteProcessMemory(h, addr, buf, size, &bytesVar)
    # Allow for whitespace / newlines between args (DOTALL)
    winapi_arg5_pat = re.compile(
        r'\b(?:WriteProcessMemory|ReadProcessMemory)\s*\('
        r'[^()]*,[^()]*,[^()]*,[^()]*,\s*&\s*(\w+)\s*\)',
        re.DOTALL,
    )

    for src_path in sorted(affected):
        if not os.path.isfile(src_path):
            continue
        rel = os.path.relpath(src_path, folder).replace("\\", "/")
        try:
            with open(src_path, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
        except OSError as exc:
            actions.append(f"[ERROR] Cannot read {rel}: {exc}")
            continue

        # Quick check — skip files that don't call these APIs at all
        if not re.search(r'\b(?:WriteProcessMemory|ReadProcessMemory)\b', content):
            continue

        changed    = False
        seen_vars  = set()

        for m in winapi_arg5_pat.finditer(content):
            var = m.group(1)
            if var in seen_vars:
                continue
            seen_vars.add(var)

            # Replace  DWORD <var>  or  DWORD& <var>  declarations
            decl_pat = re.compile(
                r'\bDWORD\b(\s*&?\s+' + re.escape(var) + r'\b)',
                re.MULTILINE,
            )
            new_content, n = decl_pat.subn(r'SIZE_T\1', content)
            if n:
                content  = new_content
                changed  = True
                actions.append(
                    f"[FIXED-SIZET] {rel}: DWORD → SIZE_T for '{var}' "
                    f"({n} declaration(s) patched)."
                )

        # Broad fallback — also catch obvious naming conventions that the
        # arg5 regex might miss if the call spans unusual whitespace
        for common in ("bytesWritten", "bytes_written", "dwWritten",
                       "bytesRead",    "bytes_read",    "dwRead",
                       "nBytes", "written", "read_bytes", "numBytes"):
            if common in seen_vars:
                continue  # already handled
            if re.search(r'\bDWORD\b\s+' + re.escape(common) + r'\b', content):
                # Only touch it if it appears near a WPM/RPM call in the file
                ctx_pat = re.compile(
                    r'(?:WriteProcessMemory|ReadProcessMemory)[^;]*&\s*'
                    + re.escape(common),
                    re.DOTALL,
                )
                if ctx_pat.search(content):
                    decl_pat = re.compile(
                        r'\bDWORD\b(\s+' + re.escape(common) + r'\b)',
                        re.MULTILINE,
                    )
                    new_content, n = decl_pat.subn(r'SIZE_T\1', content)
                    if n:
                        content = new_content
                        changed = True
                        seen_vars.add(common)
                        actions.append(
                            f"[FIXED-SIZET] {rel}: DWORD → SIZE_T for '{common}' "
                            f"(fallback match, {n} declaration(s))."
                        )

        if changed:
            try:
                with open(src_path, "w", encoding="utf-8") as fh:
                    fh.write(content)
            except OSError as exc:
                actions.append(f"[ERROR] Cannot write {rel}: {exc}")
        else:
            # No DWORD decls found even though the call is there — file
            # may already be partially fixed or uses a different pattern.
            actions.append(
                f"[WARN] {rel}: WriteProcessMemory/ReadProcessMemory found "
                f"but no DWORD declarations matched — inspect manually."
            )

    if not actions:
        actions.append("[INFO] No files required DWORD → SIZE_T patching.")

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 12: ZSTD / OpenSSL / C4101 via vcpkg
# ─────────────────────────────────────────────

# Packages Build Doctor knows how to install via vcpkg
# Maps a detection regex → vcpkg package name(s) + human label
_VCPKG_PACKAGE_MAP = [
    # (header/symbol pattern,  vcpkg_triplet_pkg,    display_name)
    (r"ZSTD_decompress|zstd(?:\.h|/zstd\.h)|error C3861.*zstd",
     "zstd:x64-windows-static", "ZSTD"),
    (r"openssl/err\.h|openssl/ssl\.h|openssl/evp\.h|openssl/bio\.h|OPENSSL_",
     "openssl:x64-windows-static", "OpenSSL"),
    (r"error C1083[^']*'[^']*zstd",
     "zstd:x64-windows-static", "ZSTD"),
    (r"error C1083[^']*'[^']*openssl",
     "openssl:x64-windows-static", "OpenSSL"),
    # Intel oneTBB — blake3_tbb.cpp and similar TBB-dependent sources
    (r"oneapi/tbb/|tbb/parallel_invoke|tbb/task_group|tbb/blocked_range"
     r"|error C1083[^']*'[^']*(?:oneapi/tbb|tbb/parallel)",
     "tbb:x64-windows-static", "Intel TBB (oneTBB)"),
    # curl
    (r"curl/curl\.h|error C1083[^']*'[^']*curl/",
     "curl:x64-windows-static", "libcurl"),
    # zlib
    (r"zlib\.h|error C1083[^']*'[^']*zlib",
     "zlib:x64-windows-static", "zlib"),
    # nlohmann JSON
    (r"nlohmann/json\.hpp|error C1083[^']*'[^']*nlohmann/",
     "nlohmann-json:x64-windows-static", "nlohmann-json"),
]

def _find_vcpkg():
    """
    Locate vcpkg.exe.  Search order:
      1. VCPKG_ROOT env var
      2. Common install locations
      3. PATH
    Returns absolute path to vcpkg.exe or None.
    """
    # Env var set by many CI systems and the official vcpkg install guide
    vcpkg_root = os.environ.get("VCPKG_ROOT", "")
    if vcpkg_root:
        candidate = os.path.join(vcpkg_root, "vcpkg.exe")
        if os.path.isfile(candidate):
            return candidate

    # Common manual install locations
    common_roots = []
    for env in ("SystemDrive", "HOMEDRIVE"):
        drive = os.environ.get(env, "C:")
        common_roots += [
            os.path.join(drive, os.sep, "vcpkg", "vcpkg.exe"),
            os.path.join(drive, os.sep, "tools", "vcpkg", "vcpkg.exe"),
            os.path.join(drive, os.sep, "src", "vcpkg", "vcpkg.exe"),
        ]
    for pf_env in ("ProgramFiles", "ProgramFiles(x86)"):
        pf = os.environ.get(pf_env, "")
        if pf:
            common_roots.append(os.path.join(pf, "vcpkg", "vcpkg.exe"))

    # Also check next to the project root (some devs vendor vcpkg in repo)
    for candidate in common_roots:
        if os.path.isfile(candidate):
            return candidate

    # Last resort: PATH
    try:
        result = subprocess.check_output(
            ["where", "vcpkg"], text=True, stderr=subprocess.DEVNULL
        ).strip().splitlines()
        if result:
            return result[0].strip()
    except Exception:
        pass

    return None


def _vcpkg_installed_root(vcpkg_exe):
    """
    Return the vcpkg installed/ directory so we can add include/lib paths.
    Tries multiple strategies:
      1. installed/ adjacent to vcpkg.exe (standard layout)
      2. VCPKG_ROOT env var
      3. Common hardcoded locations (C:\\vcpkg, %APPDATA%\\vcpkg, etc.)
    """
    # Strategy 1: installed/ next to the exe (most common)
    vcpkg_dir = os.path.dirname(vcpkg_exe)
    installed = os.path.join(vcpkg_dir, "installed")
    if os.path.isdir(installed):
        return installed

    # Strategy 2: VCPKG_ROOT env var
    vcpkg_root = os.environ.get("VCPKG_ROOT", "")
    if vcpkg_root:
        candidate = os.path.join(vcpkg_root, "installed")
        if os.path.isdir(candidate):
            return candidate

    # Strategy 3: walk up from exe location (handles symlinked vcpkg.exe in PATH)
    parent = os.path.dirname(vcpkg_dir)
    for _ in range(3):
        candidate = os.path.join(parent, "installed")
        if os.path.isdir(candidate):
            return candidate
        parent = os.path.dirname(parent)

    # Strategy 4: common install locations
    for env in ("SystemDrive", "HOMEDRIVE"):
        drive = os.environ.get(env, "C:")
        for sub in (r"vcpkg\installed", r"tools\vcpkg\installed", r"src\vcpkg\installed"):
            candidate = os.path.join(drive, os.sep, sub)
            if os.path.isdir(candidate):
                return candidate

    return None


def _inject_vcpkg_paths(folder, vcpkg_installed_root, packages, actions):
    """
    After vcpkg installs packages, find their include/ and lib/ directories
    and inject them into every .vcxproj under `folder`.
    """
    import xml.etree.ElementTree as ET

    if not vcpkg_installed_root or not os.path.isdir(vcpkg_installed_root):
        actions.append("[WARN] Cannot locate vcpkg installed/ directory — add paths manually.")
        return

    # Collect include dirs and lib dirs for all installed triplets
    new_inc_dirs = set()
    new_lib_dirs = set()
    new_libs     = set()

    for entry in os.listdir(vcpkg_installed_root):
        triplet_dir = os.path.join(vcpkg_installed_root, entry)
        if not os.path.isdir(triplet_dir):
            continue
        inc = os.path.join(triplet_dir, "include")
        lib = os.path.join(triplet_dir, "lib")
        if os.path.isdir(inc):
            new_inc_dirs.add(inc)
        if os.path.isdir(lib):
            new_lib_dirs.add(lib)
            # Collect .lib files for AdditionalDependencies
            for f in os.listdir(lib):
                if f.lower().endswith(".lib") and not f.lower().startswith("zlib"):
                    new_libs.add(f)

    if not new_inc_dirs and not new_lib_dirs:
        actions.append("[WARN] vcpkg installed/ found but no include/lib dirs detected.")
        return

    all_vcxproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    if not all_vcxproj:
        actions.append("[SKIP] No .vcxproj to patch with vcpkg paths.")
        return

    for vcxproj_path in all_vcxproj:
        proj_dir = os.path.dirname(vcxproj_path)
        fname    = os.path.basename(vcxproj_path)

        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def _t(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        changed = False

        for idg in root.iter(_t("ItemDefinitionGroup")):
            clc = idg.find(_t("ClCompile"))
            if clc is not None:
                aid = clc.find(_t("AdditionalIncludeDirectories"))
                if aid is None:
                    aid = ET.SubElement(clc, _t("AdditionalIncludeDirectories"))
                    aid.text = "%(AdditionalIncludeDirectories)"

                existing_text = (aid.text or "").replace(";%(AdditionalIncludeDirectories)", "").rstrip(";")
                existing_norm = {
                    os.path.normpath(p).lower()
                    for p in existing_text.split(";") if p.strip()
                }
                parts = [p for p in existing_text.split(";") if p.strip()]
                for inc in sorted(new_inc_dirs):
                    if os.path.normpath(inc).lower() not in existing_norm:
                        parts.append(inc)
                        existing_norm.add(os.path.normpath(inc).lower())
                        changed = True
                aid.text = ";".join(parts) + ";%(AdditionalIncludeDirectories)"

            link = idg.find(_t("Link"))
            if link is not None and new_lib_dirs:
                # AdditionalLibraryDirectories
                ald = link.find(_t("AdditionalLibraryDirectories"))
                if ald is None:
                    ald = ET.SubElement(link, _t("AdditionalLibraryDirectories"))
                    ald.text = "%(AdditionalLibraryDirectories)"
                existing_ld = (ald.text or "").replace(";%(AdditionalLibraryDirectories)", "").rstrip(";")
                existing_ld_norm = {
                    os.path.normpath(p).lower()
                    for p in existing_ld.split(";") if p.strip()
                }
                ld_parts = [p for p in existing_ld.split(";") if p.strip()]
                for lib in sorted(new_lib_dirs):
                    if os.path.normpath(lib).lower() not in existing_ld_norm:
                        ld_parts.append(lib)
                        existing_ld_norm.add(os.path.normpath(lib).lower())
                        changed = True
                ald.text = ";".join(ld_parts) + ";%(AdditionalLibraryDirectories)"

                # AdditionalDependencies
                if new_libs:
                    ad = link.find(_t("AdditionalDependencies"))
                    if ad is None:
                        ad = ET.SubElement(link, _t("AdditionalDependencies"))
                        ad.text = "%(AdditionalDependencies)"
                    existing_ad = (ad.text or "").replace(";%(AdditionalDependencies)", "").rstrip(";")
                    existing_ad_set = {p.lower() for p in existing_ad.split(";") if p.strip()}
                    ad_parts = [p for p in existing_ad.split(";") if p.strip()]
                    for lib_file in sorted(new_libs):
                        if lib_file.lower() not in existing_ad_set:
                            ad_parts.append(lib_file)
                            existing_ad_set.add(lib_file.lower())
                            changed = True
                    ad.text = ";".join(ad_parts) + ";%(AdditionalDependencies)"

        if changed:
            if xmlns:
                ET.register_namespace("", xmlns)
            tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)
            actions.append(f"[FIXED-VCPKG] {fname}: injected vcpkg include/lib paths.")
        else:
            actions.append(f"[OK] {fname}: vcpkg paths already present or no ClCompile/Link found.")


def _suppress_warning_in_vcxproj(folder, warning_number, actions):
    """
    Add /wd<number> to DisableSpecificWarnings in every .vcxproj ClCompile block.
    Used to auto-suppress C4101 (unreferenced local variable) which is noise.
    """
    import xml.etree.ElementTree as ET

    all_vcxproj = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".vcxproj"):
                all_vcxproj.append(os.path.join(rootdir, fname))

    for vcxproj_path in all_vcxproj:
        fname = os.path.basename(vcxproj_path)
        try:
            tree = ET.parse(vcxproj_path)
            root = tree.getroot()
        except ET.ParseError as exc:
            actions.append(f"[SKIP] {fname}: XML parse error — {exc}")
            continue

        ns_m  = re.match(r"^\{(.*?)\}", root.tag)
        xmlns = ns_m.group(1) if ns_m else ""

        def _t(name):
            return f"{{{xmlns}}}{name}" if xmlns else name

        changed = False
        for idg in root.iter(_t("ItemDefinitionGroup")):
            clc = idg.find(_t("ClCompile"))
            if clc is None:
                continue
            dsw = clc.find(_t("DisableSpecificWarnings"))
            if dsw is None:
                dsw = ET.SubElement(clc, _t("DisableSpecificWarnings"))
                dsw.text = "%(DisableSpecificWarnings)"
            existing = (dsw.text or "").replace(";%(DisableSpecificWarnings)", "").rstrip(";")
            existing_set = {w.strip() for w in existing.split(";") if w.strip()}
            if str(warning_number) not in existing_set:
                parts = [w for w in existing.split(";") if w.strip()]
                parts.append(str(warning_number))
                dsw.text = ";".join(parts) + ";%(DisableSpecificWarnings)"
                changed = True

        if changed:
            if xmlns:
                ET.register_namespace("", xmlns)
            tree.write(vcxproj_path, encoding="utf-8", xml_declaration=True)
            actions.append(f"[FIXED-WARN] {fname}: suppressed C{warning_number} (DisableSpecificWarnings).")


def fix_vcpkg_deps(folder, build_output=""):
    """
    Auto-Fix Pass 12 — ZSTD, OpenSSL, and other C3861/C1083 external deps.

    Strategy:
      1. Detect which packages are needed from build_output.
      2. Locate or bootstrap-install vcpkg.
      3. Run `vcpkg install <pkg>` for each missing package.
      4. Inject the vcpkg include/ and lib/ paths into every .vcxproj.
      5. Suppress C4101 (unreferenced local 'e') automatically.

    Returns a list of action strings.
    """
    actions = []

    # ── 0. Suppress C4101 (unreferenced local variable 'e') ──────────────────
    if re.search(r"warning C4101", build_output, re.IGNORECASE):
        actions.append("[*] C4101 detected — suppressing via DisableSpecificWarnings...")
        _suppress_warning_in_vcxproj(folder, 4101, actions)

    # ── 0b. Special case: openssl/err.h from httplib.h optional support ──────
    # httplib.h only includes openssl headers when CPPHTTPLIB_OPENSSL_SUPPORT
    # is defined. If the project doesn't define it but the header appears
    # anyway (e.g. transitively), suppress the false trigger by injecting
    # CPPHTTPLIB_OPENSSL_SUPPORT=0 — instead of forcing a full OpenSSL install.
    _suppress_httplib_openssl = False
    _httplib_present = any(
        f.lower() in ("httplib.h", "httplib.hpp")
        for _, _, files in os.walk(folder)
        for f in files
    )
    if _httplib_present and re.search(r"openssl/(?:err|ssl|evp|bio)\.h", build_output, re.IGNORECASE):
        _defines_openssl_support = False
        for rootdir, _, files in os.walk(folder):
            for fname in files:
                if fname.lower().endswith((".cpp", ".h", ".hpp", ".vcxproj")):
                    try:
                        content = open(os.path.join(rootdir, fname),
                                       encoding="utf-8", errors="ignore").read()
                        if "CPPHTTPLIB_OPENSSL_SUPPORT" in content:
                            _defines_openssl_support = True
                            break
                    except OSError:
                        pass
            if _defines_openssl_support:
                break
        if not _defines_openssl_support:
            _suppress_httplib_openssl = True

    # ── 1. Determine which vcpkg packages are needed ──────────────────────────
    packages_needed = []
    seen_pkgs = set()
    for pattern, pkg, label in _VCPKG_PACKAGE_MAP:
        if re.search(pattern, build_output, re.IGNORECASE):
            if pkg not in seen_pkgs:
                packages_needed.append((pkg, label))
                seen_pkgs.add(pkg)

    if not packages_needed:
        if not re.search(r"warning C4101", build_output, re.IGNORECASE):
            actions.append("[INFO] No ZSTD/OpenSSL/TBB/vcpkg errors detected.")
        return actions

    # ── 1b. Apply httplib OpenSSL suppression if appropriate ─────────────────
    if _suppress_httplib_openssl and any("openssl" in p.lower() for p, _ in packages_needed):
        actions.append(
            "[INFO] openssl/err.h error comes from optional httplib.h support — "
            "CPPHTTPLIB_OPENSSL_SUPPORT is not defined in this project. "
            "Suppressing with preprocessor define instead of installing OpenSSL."
        )
        packages_needed = [(p, l) for p, l in packages_needed if "openssl" not in p.lower()]
        seen_pkgs.discard("openssl:x64-windows-static")
        # Inject CPPHTTPLIB_OPENSSL_SUPPORT=0 into every .vcxproj
        import xml.etree.ElementTree as ET
        _DEFINE_TO_ADD = "CPPHTTPLIB_OPENSSL_SUPPORT=0"
        for rootdir, _, files in os.walk(folder):
            for vcf in files:
                if not vcf.lower().endswith(".vcxproj"):
                    continue
                vpath = os.path.join(rootdir, vcf)
                try:
                    vtree = ET.parse(vpath)
                    vroot = vtree.getroot()
                except ET.ParseError:
                    continue
                vns_m = re.match(r"^\{(.*?)\}", vroot.tag)
                vxmlns = vns_m.group(1) if vns_m else ""
                def _tv(n): return f"{{{vxmlns}}}{n}" if vxmlns else n
                vchanged = False
                for idg in vroot.iter(_tv("ItemDefinitionGroup")):
                    clc = idg.find(_tv("ClCompile"))
                    if clc is None: continue
                    ppd = clc.find(_tv("PreprocessorDefinitions"))
                    if ppd is None:
                        ppd = ET.SubElement(clc, _tv("PreprocessorDefinitions"))
                        ppd.text = "%(PreprocessorDefinitions)"
                    existing = (ppd.text or "").replace(";%(PreprocessorDefinitions)", "").rstrip(";")
                    if _DEFINE_TO_ADD not in existing:
                        ppd.text = existing.rstrip(";") + f";{_DEFINE_TO_ADD};%(PreprocessorDefinitions)"
                        vchanged = True
                if vchanged:
                    if vxmlns: ET.register_namespace("", vxmlns)
                    vtree.write(vpath, encoding="utf-8", xml_declaration=True)
                    actions.append(f"[FIXED-HTTPLIB] {vcf}: added {_DEFINE_TO_ADD} — suppressed optional OpenSSL.")
        if not packages_needed:
            return actions

    actions.append(f"[*] Packages needed: {', '.join(label for _, label in packages_needed)}")

    # ── 2. Locate vcpkg ───────────────────────────────────────────────────────
    vcpkg_exe = _find_vcpkg()

    if not vcpkg_exe:
        # Bootstrap vcpkg into C:\vcpkg
        vcpkg_dir = r"C:\vcpkg"
        actions.append(f"[*] vcpkg not found — attempting to clone and bootstrap into {vcpkg_dir}...")
        try:
            if not os.path.isdir(vcpkg_dir):
                clone_proc = subprocess.run(
                    ["git", "clone", "https://github.com/microsoft/vcpkg.git", vcpkg_dir],
                    capture_output=True, text=True, timeout=300
                )
                out = (clone_proc.stdout or "") + (clone_proc.stderr or "")
                rc  = clone_proc.returncode
                if rc != 0:
                    actions.append(f"[ERROR] git clone vcpkg failed (exit {rc}) — install vcpkg manually: https://vcpkg.io/en/getting-started")
                    actions.append("[MANUAL] Run: git clone https://github.com/microsoft/vcpkg C:\\vcpkg && C:\\vcpkg\\bootstrap-vcpkg.bat")
                    return actions
                actions.append("[+] vcpkg cloned.")

            bootstrap = os.path.join(vcpkg_dir, "bootstrap-vcpkg.bat")
            if os.path.isfile(bootstrap):
                # Must use shell=True on Windows to execute .bat files
                proc = subprocess.run(
                    f'"{bootstrap}" -disableMetrics',
                    shell=True,
                    capture_output=True, text=True, timeout=180
                )
                if proc.returncode == 0:
                    actions.append("[+] vcpkg bootstrapped successfully.")
                else:
                    actions.append(f"[WARN] bootstrap-vcpkg.bat exited {proc.returncode} — may still work.")

            vcpkg_exe = os.path.join(vcpkg_dir, "vcpkg.exe")
            if not os.path.isfile(vcpkg_exe):
                actions.append("[ERROR] vcpkg.exe not found after bootstrap. Install manually.")
                actions.append("[MANUAL] https://vcpkg.io/en/getting-started")
                return actions
        except Exception as exc:
            actions.append(f"[ERROR] vcpkg bootstrap failed: {exc}")
            actions.append("[MANUAL] Install vcpkg: https://vcpkg.io/en/getting-started")
            actions.append("[MANUAL] Then run: vcpkg install zstd:x64-windows-static openssl:x64-windows-static")
            return actions

    actions.append(f"[INFO] Using vcpkg at: {vcpkg_exe}")

    # ── 3. Install each package ───────────────────────────────────────────────
    for pkg, label in packages_needed:
        actions.append(f"[*] Installing {label} via vcpkg ({pkg})...")
        try:
            proc = subprocess.run(
                [vcpkg_exe, "install", pkg, "--recurse"],
                capture_output=True, text=True,
                encoding="utf-8", errors="ignore",
                timeout=600
            )
            output = (proc.stdout or "") + (proc.stderr or "")
            for line in output.splitlines():
                line = line.strip()
                if not line:
                    continue
                lo = line.lower()
                if "error" in lo or "fail" in lo:
                    actions.append(f"  [ERR] {line}")
                elif "already installed" in lo or "up-to-date" in lo:
                    actions.append(f"  [OK] {label} already installed.")
                elif "installing" in lo or "succeed" in lo or "package" in lo:
                    actions.append(f"  [+] {line}")

            if proc.returncode == 0:
                actions.append(f"[FIXED-VCPKG] {label} installed successfully.")
            else:
                actions.append(f"[WARN] vcpkg install {pkg} exited {proc.returncode} — check output above.")
        except subprocess.TimeoutExpired:
            actions.append(f"[ERROR] vcpkg install {label} timed out (>10 min) — run manually:")
            actions.append(f"[MANUAL] {vcpkg_exe} install {pkg}")
        except Exception as exc:
            actions.append(f"[ERROR] vcpkg install {label} failed: {exc}")

    # ── 4. Inject vcpkg include/lib paths into .vcxproj ──────────────────────
    installed_root = _vcpkg_installed_root(vcpkg_exe)

    # Fallback: if installed/ can't be found via discovery, derive from exe path
    if not installed_root:
        vcpkg_dir_fb = os.path.dirname(vcpkg_exe)
        fallback_installed = os.path.join(vcpkg_dir_fb, "installed")
        # Create the path string anyway so manual hint is accurate even if dir is absent
        actions.append(f"[WARN] Could not auto-locate vcpkg installed/ dir — using derived path.")
        installed_root = fallback_installed  # _inject_vcpkg_paths checks isdir internally

    if os.path.isdir(installed_root):
        actions.append(f"[*] Injecting vcpkg paths from: {installed_root}")
        _inject_vcpkg_paths(folder, installed_root, packages_needed, actions)
    else:
        # Last-resort: inject the standard x64-windows-static paths directly
        vcpkg_dir_lr = os.path.dirname(vcpkg_exe)
        inc_hint = os.path.join(vcpkg_dir_lr, "installed", "x64-windows-static", "include")
        lib_hint = os.path.join(vcpkg_dir_lr, "installed", "x64-windows-static", "lib")
        actions.append("[WARN] vcpkg installed/ not found on disk yet — paths will be injected as hints.")
        actions.append(f"[MANUAL] Manually add to AdditionalIncludeDirectories: {inc_hint}")
        actions.append(f"[MANUAL] Manually add to AdditionalLibraryDirectories: {lib_hint}")
        # Still attempt injection — the dirs may exist after the install completes
        _inject_vcpkg_paths(folder, os.path.join(vcpkg_dir_lr, "installed"), packages_needed, actions)

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Pass 13: MSB3202 — Missing Project Files in .sln
# ─────────────────────────────────────────────

def fix_msb3202(folder, last_build_output="", config=None):
    """
    Handles MSB3202: 'The project file X was not found.'

    Strategy (per missing project file):
      A. If it's a .vcxproj and the target folder contains .cpp/.c sources
         → generate a minimal .vcxproj via generate_vcxproj().
      B. If it's a .csproj and the target folder contains .cs sources
         → generate a minimal SDK-style .csproj.
      C. If the project folder is completely empty / absent
         → remove the dead Project() entry from the .sln so MSBuild
           stops complaining about it.

    Returns a list of action strings.
    """
    import uuid as _uuid
    import xml.etree.ElementTree as ET

    if config is None:
        config = {}

    actions = []

    # ── 1. Parse MSB3202 lines from build output ─────────────────────────────
    # Example line:
    #   C:\path\to\LunarWare.sln.metaproj : error MSB3202: The project file
    #   "C:\path\to\Base\Base.vcxproj" was not found.
    msb3202_pat = re.compile(
        r'error MSB3202[^\n]*?"([^"]+\.(?:vcxproj|csproj|vbproj))"',
        re.IGNORECASE
    )

    missing_projects = []
    for m in msb3202_pat.finditer(last_build_output):
        path = m.group(1).strip()
        if path not in missing_projects:
            missing_projects.append(path)

    if not missing_projects:
        actions.append("[INFO] No MSB3202 errors found in build output.")
        return actions

    actions.append(f"[INFO] MSB3202: {len(missing_projects)} missing project file(s) detected.")

    # ── 2. Find the .sln file(s) for later dead-ref removal ──────────────────
    sln_files = []
    for rootdir, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(".sln"):
                sln_files.append(os.path.join(rootdir, fname))

    def _remove_from_sln(missing_abs):
        """Remove the Project(...) block for a missing file from all .sln files."""
        removed_any = False
        for sln_path in sln_files:
            try:
                with open(sln_path, "r", encoding="utf-8-sig", errors="ignore") as f:
                    sln_text = f.read()
            except OSError as exc:
                actions.append(f"[ERROR] Cannot read {os.path.basename(sln_path)}: {exc}")
                continue

            # Match the Project("...") = "Name", "relative\path.vcxproj", "{GUID}" block
            # and the matching EndProject line, tolerating forward/back slashes
            escaped_name = re.escape(os.path.basename(missing_abs))
            # Build a pattern that matches the path flexibly (either slash style)
            abs_norm = os.path.normpath(missing_abs)
            # Try to find relative path variants inside the sln
            proj_block_pat = re.compile(
                r'^Project\("[^"]*"\)\s*=\s*"[^"]*",\s*"[^"]*' +
                re.escape(escaped_name) +
                r'[^"]*",\s*"[^"]*"\s*\r?\nEndProject\r?\n?',
                re.MULTILINE | re.IGNORECASE
            )
            # Broader fallback: match by any path that ends with the same filename
            broad_pat = re.compile(
                r'^Project\("[^"]*"\)\s*=\s*"[^"]*",\s*"(?:[^"]*[/\\])?' +
                re.escape(os.path.basename(missing_abs)) +
                r'",\s*"(\{[A-F0-9\-]+\})"\s*\r?\nEndProject\r?\n?',
                re.MULTILINE | re.IGNORECASE
            )

            # Collect GUIDs to remove from GlobalSection too
            guids_to_remove = set()
            for m2 in broad_pat.finditer(sln_text):
                guids_to_remove.add(m2.group(1).upper())

            new_text = broad_pat.sub("", sln_text)
            if new_text == sln_text:
                # Try the exact absolute path (forward slashes)
                abs_fwd = missing_abs.replace("\\", "/")
                abs_bck = missing_abs.replace("/", "\\")
                for abs_var in (abs_fwd, abs_bck):
                    exact_pat = re.compile(
                        r'^Project\("[^"]*"\)\s*=\s*"[^"]*",\s*"' +
                        re.escape(abs_var) +
                        r'",\s*"(\{[A-F0-9\-]+\})"\s*\r?\nEndProject\r?\n?',
                        re.MULTILINE | re.IGNORECASE
                    )
                    for m3 in exact_pat.finditer(sln_text):
                        guids_to_remove.add(m3.group(1).upper())
                    new_text = exact_pat.sub("", new_text)

            # Also strip corresponding GlobalSection entries for removed GUIDs
            for guid in guids_to_remove:
                guid_esc = re.escape(guid)
                new_text = re.sub(
                    r'^\s*' + guid_esc + r'\.[^=\n]+=[^\n]*\n',
                    "", new_text, flags=re.MULTILINE | re.IGNORECASE
                )

            if new_text != sln_text:
                try:
                    with open(sln_path, "w", encoding="utf-8") as f:
                        f.write(new_text)
                    actions.append(
                        f"[FIXED-MSB3202] {os.path.basename(sln_path)}: "
                        f"removed dead reference to {os.path.basename(missing_abs)}"
                        + (f" (GUID(s): {', '.join(sorted(guids_to_remove))})" if guids_to_remove else "")
                    )
                    removed_any = True
                except OSError as exc:
                    actions.append(f"[ERROR] Cannot write {os.path.basename(sln_path)}: {exc}")
            else:
                actions.append(
                    f"[WARN] {os.path.basename(sln_path)}: could not locate "
                    f"Project() block for {os.path.basename(missing_abs)} — remove it manually."
                )
        return removed_any

    # ── 3. Process each missing project ──────────────────────────────────────
    for proj_path in missing_projects:
        proj_abs  = proj_path  # already absolute from MSBuild output
        proj_dir  = os.path.dirname(proj_abs)
        proj_name = os.path.splitext(os.path.basename(proj_abs))[0]
        ext       = os.path.splitext(proj_abs)[1].lower()

        actions.append(f"[*] Processing missing: {proj_abs}")

        # If the file already exists now (race / already fixed), skip generation
        if os.path.isfile(proj_abs):
            actions.append(f"[OK] {os.path.basename(proj_abs)}: file now exists — no action needed.")
            continue

        # Ensure the directory exists (create it if the whole folder is absent)
        try:
            os.makedirs(proj_dir, exist_ok=True)
        except OSError as exc:
            actions.append(f"[ERROR] Cannot create directory {proj_dir}: {exc}")
            _remove_from_sln(proj_abs)
            continue

        # ── Strategy A: generate .vcxproj ────────────────────────────────────
        if ext == ".vcxproj":
            scan = scan_project(proj_dir)
            has_sources = bool(scan["cpp"] or scan["c"])

            if has_sources:
                try:
                    gen_config = dict(config)
                    gen_config.setdefault("config", "Release")
                    generated = generate_vcxproj(proj_dir, gen_config, scan)
                    # generate_vcxproj names the file after the folder; rename to
                    # match the expected project name if they differ.
                    if os.path.normpath(generated).lower() != os.path.normpath(proj_abs).lower():
                        os.replace(generated, proj_abs)
                    actions.append(
                        f"[FIXED-MSB3202] Generated {os.path.basename(proj_abs)} "
                        f"from {len(scan['cpp'] + scan['c'])} source file(s) in {proj_dir}"
                    )
                except Exception as exc:
                    actions.append(f"[ERROR] generate_vcxproj failed for {proj_name}: {exc}")
                    _remove_from_sln(proj_abs)
            else:
                # No sources → generate a minimal placeholder .vcxproj (empty ItemGroup)
                proj_guid = "{" + str(_uuid.uuid4()).upper() + "}"
                conf      = config.get("config", "Release")
                stub = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Auto-generated stub by Build Doctor (MSB3202 fix) — add source files and rebuild. -->
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="{conf}|x64">
      <Configuration>{conf}</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <PropertyGroup Label="Globals">
    <ProjectGuid>{proj_guid}</ProjectGuid>
    <RootNamespace>{proj_name}</RootNamespace>
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='{conf}|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>false</UseDebugLibraries>
    <PlatformToolset>v143</PlatformToolset>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />
  <ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='{conf}|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <Optimization>MaxSpeed</Optimization>
      <PreprocessorDefinitions>NDEBUG;_CONSOLE;%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <LanguageStandard>stdcpp17</LanguageStandard>
    </ClCompile>
    <Link>
      <SubSystem>Console</SubSystem>
      <GenerateDebugInformation>false</GenerateDebugInformation>
    </Link>
  </ItemDefinitionGroup>
  <ItemGroup />
  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />
</Project>
"""
                try:
                    with open(proj_abs, "w", encoding="utf-8") as f:
                        f.write(stub)
                    actions.append(
                        f"[FIXED-MSB3202] Created stub {os.path.basename(proj_abs)} "
                        f"(no sources found in {proj_dir} — add .cpp files and rebuild)."
                    )
                except OSError as exc:
                    actions.append(f"[ERROR] Cannot write stub {os.path.basename(proj_abs)}: {exc}")
                    _remove_from_sln(proj_abs)

        # ── Strategy B: generate .csproj ─────────────────────────────────────
        elif ext in (".csproj", ".vbproj"):
            scan = scan_project(proj_dir)
            cs_files = scan.get("cs", [])

            if cs_files:
                # Build SDK-style .csproj with all found .cs files as Compile entries
                compile_items = "\n".join(
                    f'    <Compile Include="{f}" />' for f in cs_files
                )
                stub = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Auto-generated by Build Doctor (MSB3202 fix) -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Library</OutputType>
    <TargetFramework>net48</TargetFramework>
    <AssemblyName>{proj_name}</AssemblyName>
    <RootNamespace>{proj_name}</RootNamespace>
    <Nullable>disable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
{compile_items}
  </ItemGroup>
</Project>
"""
                try:
                    with open(proj_abs, "w", encoding="utf-8") as f:
                        f.write(stub)
                    actions.append(
                        f"[FIXED-MSB3202] Generated {os.path.basename(proj_abs)} "
                        f"with {len(cs_files)} .cs file(s). "
                        f"Review <TargetFramework> and <OutputType> before rebuilding."
                    )
                except OSError as exc:
                    actions.append(f"[ERROR] Cannot write {os.path.basename(proj_abs)}: {exc}")
                    _remove_from_sln(proj_abs)
            else:
                # No .cs files → minimal SDK stub
                stub = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Auto-generated stub by Build Doctor (MSB3202 fix) — add source files and rebuild. -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Library</OutputType>
    <TargetFramework>net48</TargetFramework>
    <AssemblyName>{proj_name}</AssemblyName>
    <RootNamespace>{proj_name}</RootNamespace>
  </PropertyGroup>
</Project>
"""
                try:
                    with open(proj_abs, "w", encoding="utf-8") as f:
                        f.write(stub)
                    actions.append(
                        f"[FIXED-MSB3202] Created stub {os.path.basename(proj_abs)} "
                        f"(no .cs files found in {proj_dir} — add sources and rebuild)."
                    )
                except OSError as exc:
                    actions.append(f"[ERROR] Cannot write stub {os.path.basename(proj_abs)}: {exc}")
                    _remove_from_sln(proj_abs)

        else:
            # Unknown extension — just remove the dead .sln reference
            actions.append(
                f"[WARN] {os.path.basename(proj_abs)}: unknown project type '{ext}' — "
                "removing dead .sln reference instead."
            )
            _remove_from_sln(proj_abs)

    return actions


# ─────────────────────────────────────────────
# Auto-Fix Loop Orchestrator
# ─────────────────────────────────────────────

# Maps error patterns → which fix functions to call automatically
_AUTO_FIX_RULES = [
    # (regex_pattern,  fix_function,   needs_build_output, label)
    # MSB3202 must run FIRST — missing project files block everything else
    (r"error MSB3202",                 "fix_msb3202",       True,  "FIX MSB3202"),
    # C4101 + ZSTD + OpenSSL + TBB: run BEFORE generic C1083/LNK passes
    (r"warning C4101|ZSTD_decompress|error C3861.*zstd"
     r"|error C1083[^']*(?:zstd|openssl)|OPENSSL_|openssl/"
     r"|oneapi/tbb/|tbb/parallel_invoke|error C1083[^']*(?:oneapi/tbb|tbb/parallel)"
     r"|curl/curl\.h|nlohmann/json\.hpp",
                                       "fix_vcpkg_deps",    True,  "FIX DEPS (vcpkg)"),
    (r"error C1083",                   "fix_cpp_includes",  True,  "FIX INCS"),
    (r"error C1010",                   "fix_pch",           True,  "FIX PCH"),
    (r"error C2664.*(?:WriteProcessMemory|ReadProcessMemory)|"
     r"(?:WriteProcessMemory|ReadProcessMemory).*DWORD.*SIZE_T",
                                       "fix_winapi_size_t", True,  "FIX SIZET"),
    (r"LNK2001|LNK2019|LNK1181|LNK1104|LNK1120", "fix_missing_libs", True, "FIX LIBS"),
    (r"error CS2001|error CS0246",     "fix_cs_files",      False, "FIX CS FILES"),
    (r"error CS0006|NU1101|NU1102|NU1103|packages\.config.*not found",
                                       "fix_dotnet_restore",False, "NUGET RESTORE"),
    (r"C4003.*LUAU_FASTFLAGVARIABLE|C2051.*BytecodeUtils|LuauBytecodeType.*undeclared"
     r"|error C1083[^']*'[^']*(?:Luau/|luau/|lua\.h|luaconf\.h|lualib\.h)",
                                       "fix_luau",          True,  "FIX LUAU"),
]

_FIX_FUNC_MAP = {
    "fix_msb3202":       lambda folder, out: fix_msb3202(folder, out),
    "fix_vcpkg_deps":    lambda folder, out: fix_vcpkg_deps(folder, out),
    "fix_cpp_includes":  lambda folder, out: fix_cpp_missing_includes(folder, out),
    "fix_pch":           lambda folder, out: fix_pch(folder, out),
    "fix_winapi_size_t": lambda folder, out: fix_winapi_size_t(folder, out),
    "fix_missing_libs":  lambda folder, out: fix_missing_libs(folder, out),
    "fix_cs_files":      lambda folder, out: fix_missing_cs_files(folder),
    "fix_dotnet_restore":lambda folder, out: _run_dotnet_restore_cmd(folder).get("output", "").splitlines(),
    "fix_luau":          lambda folder, out: fix_luau_submodule(folder, last_build_output=out),
}


def auto_fix_from_output(folder, build_output, emit_line=None):
    """
    Given build output, automatically determines which fix passes apply
    and runs them. Returns (actions_list, fix_labels_applied).
    """
    actions_all   = []
    labels_applied = []

    def log(text, cls="dim"):
        actions_all.append(text)
        if emit_line:
            emit_line(text, cls)

    for pattern, func_name, needs_output, label in _AUTO_FIX_RULES:
        if re.search(pattern, build_output, re.IGNORECASE):
            log(f"[AUTO-FIX] Detected pattern → running {label}...", "warn")
            try:
                out_arg = build_output if needs_output else ""
                fix_results = _FIX_FUNC_MAP[func_name](folder, out_arg)
                for line in fix_results:
                    cls = "info"  if line.startswith("[FIXED") else \
                          "error" if line.startswith("[ERROR") else \
                          "warn"  if line.startswith("[WARN")  else "dim"
                    log(line, cls)
                labels_applied.append(label)
            except Exception as exc:
                log(f"[ERROR] {label} threw: {exc}", "error")

    if not labels_applied:
        log("[AUTO-FIX] No auto-applicable fixes matched this build output.", "dim")

    return actions_all, labels_applied


# ─────────────────────────────────────────────
# Build Output SHA256 Hash
# ─────────────────────────────────────────────

def sha256_file(path):
    """Returns hex SHA256 of a file, or None on error."""
    import hashlib
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(65536), b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return None


# ─────────────────────────────────────────────
# C++ Creator: Template Library
# ─────────────────────────────────────────────

CPP_TEMPLATES = {
    "console_hello": {
        "label": "Hello World (Console)",
        "desc":  "Classic entry point — prints a message and exits cleanly.",
        "cpp": '''\
#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    std::cout << "Hello, World!" << std::endl;
    std::cout << "Build Doctor C++ Creator — ready to hack." << std::endl;
    return 0;
}
''',
        "headers": [],
    },

    "winapi_window": {
        "label": "Win32 Window (WinAPI)",
        "desc":  "Minimal native Win32 window with message loop.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            RECT rc;
            GetClientRect(hWnd, &rc);
            DrawText(hdc, TEXT("Build Doctor — Win32 Window"), -1, &rc,
                     DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            EndPaint(hWnd, &ps);
            return 0;
        }
    }
    return DefWindowProc(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int nCmdShow) {
    const TCHAR CLASS_NAME[] = TEXT("BuildDoctorWindow");

    WNDCLASS wc = {};
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);

    if (!RegisterClass(&wc)) return 1;

    HWND hWnd = CreateWindowEx(
        0, CLASS_NAME, TEXT("Build Doctor — Win32"),
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
        nullptr, nullptr, hInstance, nullptr
    );
    if (!hWnd) return 1;

    ShowWindow(hWnd, nCmdShow);
    UpdateWindow(hWnd);

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
''',
        "headers": [],
        "subsystem": "Windows",
    },

    "process_injector": {
        "label": "Process Memory Tool",
        "desc":  "Opens a process by name, reads/writes memory using correct SIZE_T types.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <iostream>
#include <string>

DWORD GetProcessIdByName(const std::wstring& name) {
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;

    PROCESSENTRY32W entry = {};
    entry.dwSize = sizeof(entry);

    DWORD pid = 0;
    if (Process32FirstW(snap, &entry)) {
        do {
            if (name == entry.szExeFile) {
                pid = entry.th32ProcessID;
                break;
            }
        } while (Process32NextW(snap, &entry));
    }
    CloseHandle(snap);
    return pid;
}

int main() {
    std::wcout << L"[*] Process Memory Tool" << std::endl;

    std::wstring targetName = L"notepad.exe";
    DWORD pid = GetProcessIdByName(targetName);
    if (!pid) {
        std::wcerr << L"[!] Process not found: " << targetName << std::endl;
        return 1;
    }

    std::wcout << L"[+] Found PID: " << pid << std::endl;

    HANDLE hProc = OpenProcess(PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION,
                               FALSE, pid);
    if (!hProc) {
        std::wcerr << L"[!] OpenProcess failed: " << GetLastError() << std::endl;
        return 1;
    }

    // Example: read 8 bytes from base address
    uintptr_t baseAddr = 0x1000;
    BYTE buffer[8]     = {};
    SIZE_T bytesRead   = 0;

    if (ReadProcessMemory(hProc, (LPCVOID)baseAddr, buffer, sizeof(buffer), &bytesRead)) {
        std::cout << "[+] Read " << bytesRead << " bytes." << std::endl;
    } else {
        std::cout << "[~] ReadProcessMemory failed at demo address (expected)." << std::endl;
    }

    CloseHandle(hProc);
    std::cout << "[+] Done." << std::endl;
    return 0;
}
''',
        "headers": [],
    },

    "dll_inject": {
        "label": "DLL Injector (LoadLibrary)",
        "desc":  "Classic LoadLibraryA DLL injector using CreateRemoteThread.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <iostream>
#include <string>

DWORD GetPidByName(const char* name) {
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    PROCESSENTRY32 pe = { sizeof(pe) };
    DWORD pid = 0;
    if (Process32First(snap, &pe)) {
        do {
            if (_stricmp(pe.szExeFile, name) == 0) { pid = pe.th32ProcessID; break; }
        } while (Process32Next(snap, &pe));
    }
    CloseHandle(snap);
    return pid;
}

bool InjectDll(DWORD pid, const char* dllPath) {
    HANDLE hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    if (!hProc) { std::cerr << "[!] OpenProcess failed\n"; return false; }

    SIZE_T pathLen = strlen(dllPath) + 1;
    LPVOID pMem    = VirtualAllocEx(hProc, nullptr, pathLen, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!pMem) { CloseHandle(hProc); return false; }

    SIZE_T written = 0;
    WriteProcessMemory(hProc, pMem, dllPath, pathLen, &written);

    HMODULE hKernel = GetModuleHandleA("kernel32.dll");
    FARPROC pLLa    = GetProcAddress(hKernel, "LoadLibraryA");

    HANDLE hThread = CreateRemoteThread(hProc, nullptr, 0,
        (LPTHREAD_START_ROUTINE)pLLa, pMem, 0, nullptr);
    if (!hThread) { VirtualFreeEx(hProc, pMem, 0, MEM_RELEASE); CloseHandle(hProc); return false; }

    WaitForSingleObject(hThread, 5000);
    VirtualFreeEx(hProc, pMem, 0, MEM_RELEASE);
    CloseHandle(hThread);
    CloseHandle(hProc);
    return true;
}

int main() {
    const char* target  = "notepad.exe";
    const char* dllPath = "C:\\path\\to\\your.dll";

    std::cout << "[*] DLL Injector\n";
    DWORD pid = GetPidByName(target);
    if (!pid) { std::cerr << "[!] " << target << " not running\n"; return 1; }
    std::cout << "[+] PID: " << pid << "\n";

    if (InjectDll(pid, dllPath))
        std::cout << "[+] Injected: " << dllPath << "\n";
    else
        std::cerr << "[!] Injection failed (error " << GetLastError() << ")\n";

    return 0;
}
''',
        "headers": [],
    },

    "network_scanner": {
        "label": "TCP Port Scanner (WinSock2)",
        "desc":  "Multi-threaded TCP connect scanner using WinSock2.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#define _WINSOCK_DEPRECATED_NO_WARNINGS
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <thread>
#include <mutex>

#pragma comment(lib, "ws2_32.lib")

std::mutex g_mtx;

bool TryConnect(const char* host, int port, int timeoutMs = 500) {
    SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) return false;

    // Set non-blocking
    u_long mode = 1;
    ioctlsocket(s, FIONBIO, &mode);

    sockaddr_in addr = {};
    addr.sin_family  = AF_INET;
    addr.sin_port    = htons((u_short)port);
    inet_pton(AF_INET, host, &addr.sin_addr);

    connect(s, (sockaddr*)&addr, sizeof(addr));

    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(s, &fds);
    timeval tv = { 0, timeoutMs * 1000 };
    bool open  = select(0, nullptr, &fds, nullptr, &tv) > 0;

    closesocket(s);
    return open;
}

int main() {
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        std::cerr << "[!] WSAStartup failed\n"; return 1;
    }

    const char* host = "127.0.0.1";
    int start = 1, end = 1024;

    std::cout << "[*] Scanning " << host << " ports " << start << "-" << end << "\n";

    std::vector<std::thread> threads;
    for (int port = start; port <= end; ++port) {
        threads.emplace_back([host, port]() {
            if (TryConnect(host, port)) {
                std::lock_guard<std::mutex> lock(g_mtx);
                std::cout << "[OPEN] Port " << port << "\n";
            }
        });
        if (threads.size() >= 64) {
            for (auto& t : threads) t.join();
            threads.clear();
        }
    }
    for (auto& t : threads) t.join();

    WSACleanup();
    std::cout << "[+] Scan complete.\n";
    return 0;
}
''',
        "headers": [],
        "extraLib": "ws2_32.lib",
    },

    "file_crypter": {
        "label": "XOR File Encryptor/Decryptor",
        "desc":  "XOR-based file encryptor — apply twice to encrypt or decrypt.",
        "cpp": '''\
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstdint>
#include <stdexcept>

std::vector<uint8_t> ReadFile(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("Cannot open: " + path);
    return { std::istreambuf_iterator<char>(f), {} };
}

void WriteFile(const std::string& path, const std::vector<uint8_t>& data) {
    std::ofstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("Cannot write: " + path);
    f.write(reinterpret_cast<const char*>(data.data()), data.size());
}

std::vector<uint8_t> XorData(std::vector<uint8_t> data, const std::string& key) {
    size_t klen = key.size();
    for (size_t i = 0; i < data.size(); ++i)
        data[i] ^= static_cast<uint8_t>(key[i % klen]);
    return data;
}

int main(int argc, char* argv[]) {
    if (argc < 4) {
        std::cout << "Usage: crypter <input> <output> <key>\\n";
        std::cout << "Apply twice to toggle encrypt/decrypt.\\n";
        return 1;
    }
    try {
        auto data    = ReadFile(argv[1]);
        auto result  = XorData(data, argv[3]);
        WriteFile(argv[2], result);
        std::cout << "[+] Done: " << data.size() << " bytes processed.\\n";
    } catch (const std::exception& ex) {
        std::cerr << "[!] " << ex.what() << "\\n";
        return 1;
    }
    return 0;
}
''',
        "headers": [],
    },

    "hook_engine": {
        "label": "Inline x64 Hook Engine",
        "desc":  "Minimal trampoline-based x64 function hook using VirtualProtect.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <iostream>
#include <cstring>
#include <cstdint>

// ── Trampoline hook for x64 ──────────────────────────────────────
// Writes a 14-byte absolute JMP: FF 25 00000000 <8-byte addr>
static constexpr size_t HOOK_SIZE = 14;

struct Hook {
    void*   target;
    void*   detour;
    uint8_t original[HOOK_SIZE];
    bool    installed = false;

    bool Install() {
        if (installed) return true;
        DWORD old;
        if (!VirtualProtect(target, HOOK_SIZE, PAGE_EXECUTE_READWRITE, &old))
            return false;

        memcpy(original, target, HOOK_SIZE);

        // FF 25 00 00 00 00  →  JMP QWORD PTR [RIP+0]
        // followed by 8-byte absolute destination
        uint8_t patch[HOOK_SIZE] = {
            0xFF, 0x25, 0x00, 0x00, 0x00, 0x00,
            0,0,0,0,0,0,0,0
        };
        uintptr_t dest = reinterpret_cast<uintptr_t>(detour);
        memcpy(patch + 6, &dest, 8);
        memcpy(target, patch, HOOK_SIZE);

        VirtualProtect(target, HOOK_SIZE, old, &old);
        FlushInstructionCache(GetCurrentProcess(), target, HOOK_SIZE);
        installed = true;
        return true;
    }

    bool Remove() {
        if (!installed) return true;
        DWORD old;
        if (!VirtualProtect(target, HOOK_SIZE, PAGE_EXECUTE_READWRITE, &old))
            return false;
        memcpy(target, original, HOOK_SIZE);
        VirtualProtect(target, HOOK_SIZE, old, &old);
        FlushInstructionCache(GetCurrentProcess(), target, HOOK_SIZE);
        installed = false;
        return true;
    }
};

// ── Demo: hook MessageBoxA ───────────────────────────────────────
Hook g_hook;
using MsgBoxFn = int(WINAPI*)(HWND, LPCSTR, LPCSTR, UINT);
MsgBoxFn g_original = nullptr;

int WINAPI DetourMsgBox(HWND hWnd, LPCSTR text, LPCSTR caption, UINT type) {
    std::cout << "[HOOK] MessageBoxA intercepted!\\n";
    std::cout << "       Caption: " << (caption ? caption : "") << "\\n";
    std::cout << "       Text:    " << (text    ? text    : "") << "\\n";
    // Call original by removing hook, calling, re-hooking
    g_hook.Remove();
    int ret = MessageBoxA(hWnd, text, caption, type);
    g_hook.Install();
    return ret;
}

int main() {
    std::cout << "[*] x64 Inline Hook Demo\\n";

    HMODULE hUser = GetModuleHandleA("user32.dll");
    void* pMsgBox = GetProcAddress(hUser, "MessageBoxA");

    g_original = reinterpret_cast<MsgBoxFn>(pMsgBox);
    g_hook      = { pMsgBox, reinterpret_cast<void*>(DetourMsgBox) };

    if (g_hook.Install()) {
        std::cout << "[+] Hook installed on MessageBoxA\\n";
        MessageBoxA(nullptr, "This call is hooked!", "Hook Demo", MB_OK);
        g_hook.Remove();
        std::cout << "[+] Hook removed\\n";
    } else {
        std::cerr << "[!] Hook failed (error " << GetLastError() << ")\\n";
    }

    return 0;
}
''',
        "headers": [],
    },

    "imgui_dx11": {
        "label": "Dear ImGui Window (DX11 + Win32)",
        "desc":  "Immediate-mode GUI app using Dear ImGui with DirectX 11 + Win32 backend. Place ImGui headers in an 'imgui/' subfolder.",
        "cpp": '''\
// ─────────────────────────────────────────────────────────────────
//  Dear ImGui — DirectX 11 + Win32 backend starter
//
//  SETUP (one-time):
//    1. Download Dear ImGui from https://github.com/ocornut/imgui
//    2. Copy these files into an "imgui/" subfolder next to main.cpp:
//         imgui.h  imgui.cpp  imgui_internal.h
//         imgui_draw.cpp  imgui_tables.cpp  imgui_widgets.cpp
//         imconfig.h  imgui_demo.cpp (optional)
//         backends/imgui_impl_win32.h  backends/imgui_impl_win32.cpp
//         backends/imgui_impl_dx11.h   backends/imgui_impl_dx11.cpp
//    3. Build Doctor will auto-detect all .cpp files; vcxproj is
//       regenerated with the imgui/ folder on the include path.
// ─────────────────────────────────────────────────────────────────

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <tchar.h>

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

// ── D3D11 globals ─────────────────────────────────────────────────
static ID3D11Device*            g_pd3dDevice           = nullptr;
static ID3D11DeviceContext*     g_pd3dDeviceContext    = nullptr;
static IDXGISwapChain*          g_pSwapChain           = nullptr;
static ID3D11RenderTargetView*  g_mainRenderTargetView = nullptr;

static bool CreateDeviceD3D(HWND hWnd);
static void CleanupDeviceD3D();
static void CreateRenderTarget();
static void CleanupRenderTarget();

// Forward declaration required by imgui_impl_win32
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

// ── Window procedure ──────────────────────────────────────────────
LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    switch (msg) {
    case WM_SIZE:
        if (g_pd3dDevice != nullptr && wParam != SIZE_MINIMIZED) {
            CleanupRenderTarget();
            g_pSwapChain->ResizeBuffers(0, (UINT)LOWORD(lParam), (UINT)HIWORD(lParam), DXGI_FORMAT_UNKNOWN, 0);
            CreateRenderTarget();
        }
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) return 0; // suppress ALT menu
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

// ── Entry point ───────────────────────────────────────────────────
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int nCmdShow) {
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0L, 0L,
                       GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr,
                       L"ImGuiApp", nullptr };
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowW(wc.lpszClassName, L"Dear ImGui — DX11 Starter",
        WS_OVERLAPPEDWINDOW, 100, 100, 1280, 800,
        nullptr, nullptr, wc.hInstance, nullptr);

    if (!CreateDeviceD3D(hwnd)) {
        CleanupDeviceD3D();
        UnregisterClassW(wc.lpszClassName, wc.hInstance);
        return 1;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    // ── ImGui setup ───────────────────────────────────────────────
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    ImGui::StyleColorsDark();

    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

    // ── State ─────────────────────────────────────────────────────
    bool show_demo_window    = true;
    bool show_another_window = false;
    ImVec4 clear_color = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);
    float  counter     = 0.0f;
    char   input_buf[256] = "Hello, ImGui!";

    // ── Main loop ─────────────────────────────────────────────────
    MSG msg = {};
    while (msg.message != WM_QUIT) {
        if (PeekMessage(&msg, nullptr, 0U, 0U, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
            continue;
        }

        // New frame
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        // ── Your UI here ─────────────────────────────────────────
        {
            ImGui::SetNextWindowPos(ImVec2(30, 30), ImGuiCond_Once);
            ImGui::SetNextWindowSize(ImVec2(420, 280), ImGuiCond_Once);
            ImGui::Begin("Build Doctor ImGui Starter");

            ImGui::Text("Edit me in main.cpp!");
            ImGui::Separator();

            ImGui::InputText("Input", input_buf, IM_ARRAYSIZE(input_buf));
            ImGui::SliderFloat("Counter", &counter, 0.0f, 100.0f);
            ImGui::ColorEdit3("BG Color", (float*)&clear_color);

            if (ImGui::Button("Click me"))
                counter += 1.0f;

            ImGui::SameLine();
            ImGui::Text("counter = %.0f", counter);

            ImGui::Spacing();
            ImGui::Checkbox("Show ImGui Demo Window", &show_demo_window);
            ImGui::Checkbox("Show Another Window",    &show_another_window);

            ImGui::Separator();
            ImGui::Text("FPS: %.1f", io.Framerate);
            ImGui::End();
        }

        if (show_demo_window)
            ImGui::ShowDemoWindow(&show_demo_window);

        if (show_another_window) {
            ImGui::Begin("Another Window", &show_another_window);
            ImGui::Text("Hello from another window!");
            if (ImGui::Button("Close Me"))
                show_another_window = false;
            ImGui::End();
        }
        // ─────────────────────────────────────────────────────────

        // Render
        ImGui::Render();
        const float cc[4] = { clear_color.x * clear_color.w,
                               clear_color.y * clear_color.w,
                               clear_color.z * clear_color.w,
                               clear_color.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nullptr);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_pSwapChain->Present(1, 0); // vsync
    }

    // Cleanup
    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
    CleanupDeviceD3D();
    DestroyWindow(hwnd);
    UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return 0;
}

// ── D3D11 helpers ─────────────────────────────────────────────────
static bool CreateDeviceD3D(HWND hWnd) {
    DXGI_SWAP_CHAIN_DESC sd = {};
    sd.BufferCount                        = 2;
    sd.BufferDesc.Width                   = 0;
    sd.BufferDesc.Height                  = 0;
    sd.BufferDesc.Format                  = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator   = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags                              = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage                        = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow                       = hWnd;
    sd.SampleDesc.Count                   = 1;
    sd.SampleDesc.Quality                 = 0;
    sd.Windowed                           = TRUE;
    sd.SwapEffect                         = DXGI_SWAP_EFFECT_DISCARD;

    UINT createDeviceFlags = 0;
    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevelArray[2] = {
        D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0
    };

    HRESULT res = D3D11CreateDeviceAndSwapChain(
        nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
        createDeviceFlags, featureLevelArray, 2,
        D3D11_SDK_VERSION, &sd, &g_pSwapChain,
        &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);

    if (res == DXGI_ERROR_UNSUPPORTED)
        res = D3D11CreateDeviceAndSwapChain(
            nullptr, D3D_DRIVER_TYPE_WARP, nullptr,
            createDeviceFlags, featureLevelArray, 2,
            D3D11_SDK_VERSION, &sd, &g_pSwapChain,
            &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);

    if (res != S_OK) return false;
    CreateRenderTarget();
    return true;
}

static void CleanupDeviceD3D() {
    CleanupRenderTarget();
    if (g_pSwapChain)        { g_pSwapChain->Release();        g_pSwapChain = nullptr; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
    if (g_pd3dDevice)        { g_pd3dDevice->Release();        g_pd3dDevice = nullptr; }
}

static void CreateRenderTarget() {
    ID3D11Texture2D* pBackBuffer = nullptr;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    if (pBackBuffer) {
        g_pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &g_mainRenderTargetView);
        pBackBuffer->Release();
    }
}

static void CleanupRenderTarget() {
    if (g_mainRenderTargetView) {
        g_mainRenderTargetView->Release();
        g_mainRenderTargetView = nullptr;
    }
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;user32.lib;gdi32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": (
            "ImGui setup required:\n"
            "  1. Download from https://github.com/ocornut/imgui\n"
            "  2. Create an 'imgui/' folder inside your project directory\n"
            "  3. Copy into imgui/: imgui.h, imgui.cpp, imgui_internal.h,\n"
            "     imgui_draw.cpp, imgui_tables.cpp, imgui_widgets.cpp, imconfig.h\n"
            "  4. Create imgui/backends/ and copy:\n"
            "     imgui_impl_win32.h/cpp  imgui_impl_dx11.h/cpp\n"
            "  Build Doctor will pick up all .cpp files automatically."
        ),
    },

    "imgui_dx11_docking": {
        "label": "Dear ImGui — Docking + Multi-Viewport",
        "desc":  "ImGui with docking layout and multi-viewport support enabled (DX11 backend). Requires ImGui docking branch.",
        "cpp": '''\
// ─────────────────────────────────────────────────────────────────
//  Dear ImGui — DX11 + Win32, Docking & Multi-Viewport enabled
//
//  SETUP: same as the standard DX11 template PLUS use the
//  "docking" branch of Dear ImGui (not the master branch):
//    git clone -b docking https://github.com/ocornut/imgui
// ─────────────────────────────────────────────────────────────────

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <tchar.h>

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

static ID3D11Device*            g_pd3dDevice           = nullptr;
static ID3D11DeviceContext*     g_pd3dDeviceContext    = nullptr;
static IDXGISwapChain*          g_pSwapChain           = nullptr;
static ID3D11RenderTargetView*  g_mainRenderTargetView = nullptr;
static bool                     g_SwapChainOccluded    = false;

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND, UINT, WPARAM, LPARAM);

static bool  CreateDeviceD3D(HWND hWnd);
static void  CleanupDeviceD3D();
static void  CreateRenderTarget();
static void  CleanupRenderTarget();

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam)) return true;
    switch (msg) {
    case WM_SIZE:
        if (wParam != SIZE_MINIMIZED) {
            CleanupRenderTarget();
            g_pSwapChain->ResizeBuffers(0, LOWORD(lParam), HIWORD(lParam), DXGI_FORMAT_UNKNOWN, 0);
            CreateRenderTarget();
        }
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) return 0;
        break;
    case WM_DESTROY:
        PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int) {
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0, 0,
        GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr, L"ImGuiDock", nullptr };
    RegisterClassExW(&wc);
    HWND hwnd = CreateWindowW(wc.lpszClassName, L"ImGui Docking Starter",
        WS_OVERLAPPEDWINDOW, 100, 100, 1440, 900, nullptr, nullptr, wc.hInstance, nullptr);

    if (!CreateDeviceD3D(hwnd)) { CleanupDeviceD3D(); return 1; }
    ShowWindow(hwnd, SW_SHOWDEFAULT); UpdateWindow(hwnd);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    // Enable docking + multi-viewport
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
    io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    ImGui::StyleColorsDark();

    // When viewports are enabled, tweak WindowRounding/WindowBg so platform windows match
    ImGuiStyle& style = ImGui::GetStyle();
    if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
        style.WindowRounding = 0.0f;
        style.Colors[ImGuiCol_WindowBg].w = 1.0f;
    }

    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

    ImVec4 clear_color = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);

    MSG msg = {};
    while (msg.message != WM_QUIT) {
        if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg); DispatchMessage(&msg); continue;
        }
        if (g_SwapChainOccluded && g_pSwapChain->Present(0, DXGI_PRESENT_TEST) == DXGI_STATUS_OCCLUDED) {
            Sleep(10); continue;
        }
        g_SwapChainOccluded = false;

        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        // ── Full-window dockspace ─────────────────────────────────
        ImGuiWindowFlags dock_flags =
            ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoDocking |
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse |
            ImGuiWindowFlags_NoResize   | ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoNavFocus;
        ImGuiViewport* vp = ImGui::GetMainViewport();
        ImGui::SetNextWindowPos(vp->WorkPos);
        ImGui::SetNextWindowSize(vp->WorkSize);
        ImGui::SetNextWindowViewport(vp->ID);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));
        ImGui::Begin("DockSpace", nullptr, dock_flags);
        ImGui::PopStyleVar(3);
        ImGui::DockSpace(ImGui::GetID("RootDock"), ImVec2(0,0), ImGuiDockNodeFlags_None);

        if (ImGui::BeginMenuBar()) {
            if (ImGui::BeginMenu("File")) {
                if (ImGui::MenuItem("Quit")) PostQuitMessage(0);
                ImGui::EndMenu();
            }
            ImGui::EndMenuBar();
        }
        ImGui::End();

        // ── Your panel windows ────────────────────────────────────
        ImGui::Begin("Properties");
        ImGui::Text("Drag me to dock/undock!");
        ImGui::ColorEdit3("Background", (float*)&clear_color);
        ImGui::Text("FPS: %.1f", io.Framerate);
        ImGui::End();

        ImGui::Begin("Viewport");
        ImGui::Text("Your rendered content goes here.");
        ImGui::End();

        ImGui::Begin("Console");
        ImGui::Text("> Build Doctor ImGui Docking Starter");
        ImGui::End();

        // Render
        ImGui::Render();
        const float cc[4] = { clear_color.x, clear_color.y, clear_color.z, clear_color.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nullptr);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

        // Update and render additional platform windows (multi-viewport)
        if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
            ImGui::UpdatePlatformWindows();
            ImGui::RenderPlatformWindowsDefault();
        }

        HRESULT hr = g_pSwapChain->Present(1, 0);
        g_SwapChainOccluded = (hr == DXGI_STATUS_OCCLUDED);
    }

    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
    CleanupDeviceD3D();
    DestroyWindow(hwnd);
    UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return 0;
}

static bool CreateDeviceD3D(HWND hWnd) {
    DXGI_SWAP_CHAIN_DESC sd = {};
    sd.BufferCount = 2; sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate = { 60, 1 }; sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT; sd.OutputWindow = hWnd;
    sd.SampleDesc = { 1, 0 }; sd.Windowed = TRUE; sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    const D3D_FEATURE_LEVEL levels[] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    D3D_FEATURE_LEVEL fl;
    HRESULT res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
        levels, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &fl, &g_pd3dDeviceContext);
    if (res == DXGI_ERROR_UNSUPPORTED)
        res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, 0,
            levels, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &fl, &g_pd3dDeviceContext);
    if (res != S_OK) return false;
    CreateRenderTarget(); return true;
}
static void CleanupDeviceD3D() {
    CleanupRenderTarget();
    if (g_pSwapChain)        { g_pSwapChain->Release();        g_pSwapChain = nullptr; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
    if (g_pd3dDevice)        { g_pd3dDevice->Release();        g_pd3dDevice = nullptr; }
}
static void CreateRenderTarget() {
    ID3D11Texture2D* pBack = nullptr;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBack));
    if (pBack) { g_pd3dDevice->CreateRenderTargetView(pBack, nullptr, &g_mainRenderTargetView); pBack->Release(); }
}
static void CleanupRenderTarget() {
    if (g_mainRenderTargetView) { g_mainRenderTargetView->Release(); g_mainRenderTargetView = nullptr; }
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;user32.lib;gdi32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": (
            "Requires the ImGui DOCKING branch:\n"
            "  git clone -b docking https://github.com/ocornut/imgui\n"
            "Then copy headers/sources into an 'imgui/' subfolder (same as DX11 template)."
        ),
    },

    # ── GUI Templates ──────────────────────────────────────────────────────────

    "win32_controls": {
        "label": "Win32 GUI — Buttons, Edit, ListBox",
        "desc":  "Native Win32 dialog with common controls: button, textbox, listbox, and label. No dependencies.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
#include <vector>

#define ID_BTN_ADD    101
#define ID_BTN_CLEAR  102
#define ID_EDIT_INPUT 103
#define ID_LIST_ITEMS 104
#define ID_LABEL_INFO 105

static HWND g_hEdit  = nullptr;
static HWND g_hList  = nullptr;
static HWND g_hLabel = nullptr;
static int  g_count  = 0;

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CreateWindowW(L"STATIC", L"Enter text:", WS_CHILD | WS_VISIBLE,
            10, 10, 80, 20, hWnd, (HMENU)ID_LABEL_INFO, nullptr, nullptr);

        g_hEdit = CreateWindowW(L"EDIT", L"", WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
            10, 35, 300, 24, hWnd, (HMENU)ID_EDIT_INPUT, nullptr, nullptr);

        CreateWindowW(L"BUTTON", L"Add", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            320, 35, 70, 24, hWnd, (HMENU)ID_BTN_ADD, nullptr, nullptr);

        CreateWindowW(L"BUTTON", L"Clear", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            400, 35, 70, 24, hWnd, (HMENU)ID_BTN_CLEAR, nullptr, nullptr);

        g_hList = CreateWindowW(L"LISTBOX", L"", WS_CHILD | WS_VISIBLE | WS_BORDER |
            LBS_NOTIFY | WS_VSCROLL,
            10, 70, 460, 280, hWnd, (HMENU)ID_LIST_ITEMS, nullptr, nullptr);

        g_hLabel = CreateWindowW(L"STATIC", L"0 items", WS_CHILD | WS_VISIBLE,
            10, 360, 200, 20, hWnd, nullptr, nullptr, nullptr);

        // Set a nice font on all controls
        HFONT hFont = CreateFontW(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Segoe UI");
        EnumChildWindows(hWnd, [](HWND hChild, LPARAM lp) -> BOOL {
            SendMessage(hChild, WM_SETFONT, lp, TRUE); return TRUE;
        }, (LPARAM)hFont);
        return 0;
    }
    case WM_COMMAND: {
        WORD id = LOWORD(wParam);
        if (id == ID_BTN_ADD) {
            wchar_t buf[256] = {};
            GetWindowTextW(g_hEdit, buf, 256);
            if (buf[0]) {
                SendMessageW(g_hList, LB_ADDSTRING, 0, (LPARAM)buf);
                SetWindowTextW(g_hEdit, L"");
                SetFocus(g_hEdit);
                ++g_count;
                SetWindowTextW(g_hLabel,
                    (std::to_wstring(g_count) + L" item(s)").c_str());
            }
        } else if (id == ID_BTN_CLEAR) {
            SendMessageW(g_hList, LB_RESETCONTENT, 0, 0);
            g_count = 0;
            SetWindowTextW(g_hLabel, L"0 items");
        }
        return 0;
    }
    case WM_DESTROY:
        PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int nShow) {
    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = L"Win32Controls";
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassExW(&wc);

    HWND hWnd = CreateWindowExW(0, L"Win32Controls", L"Win32 Controls Demo",
        WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX & ~WS_THICKFRAME,
        CW_USEDEFAULT, CW_USEDEFAULT, 500, 430,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hWnd, nShow);
    UpdateWindow(hWnd);

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
''',
        "headers": [],
        "subsystem": "Windows",
    },

    "win32_dark_window": {
        "label": "Win32 Dark Mode Window",
        "desc":  "Win32 window with dark title bar (DwmSetWindowAttribute) and GDI dark client area — no dependencies.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <dwmapi.h>
#include <string>

#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "gdi32.lib")

// Dark mode colours
static const COLORREF BG_COLOR   = RGB(18,  18,  20);
static const COLORREF TEXT_COLOR = RGB(220, 220, 220);
static const COLORREF BTN_BG     = RGB(40,  40,  45);
static const COLORREF BTN_HOVER  = RGB(60,  60,  68);

static HBRUSH g_hBgBrush   = nullptr;
static HBRUSH g_hBtnBrush  = nullptr;
static HBRUSH g_hHoverBrush= nullptr;
static HFONT  g_hFont       = nullptr;
static bool   g_btnHover    = false;

#define ID_BTN 201

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        // Enable dark title bar
        BOOL dark = TRUE;
        DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark, sizeof(dark));

        g_hBgBrush    = CreateSolidBrush(BG_COLOR);
        g_hBtnBrush   = CreateSolidBrush(BTN_BG);
        g_hHoverBrush = CreateSolidBrush(BTN_HOVER);
        g_hFont = CreateFontW(18, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Segoe UI");

        CreateWindowW(L"BUTTON", L"Click Me", WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
            180, 140, 140, 36, hWnd, (HMENU)ID_BTN, nullptr, nullptr);
        return 0;
    }
    case WM_ERASEBKGND: {
        RECT rc; GetClientRect(hWnd, &rc);
        FillRect((HDC)wParam, &rc, g_hBgBrush);
        return 1;
    }
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        SetBkColor(hdc, BG_COLOR);
        SetTextColor(hdc, TEXT_COLOR);
        SetBkMode(hdc, TRANSPARENT);
        HFONT old = (HFONT)SelectObject(hdc, g_hFont);
        RECT rc = { 0, 60, 500, 110 };
        DrawTextW(hdc, L"Dark Mode Win32 Window", -1, &rc, DT_CENTER | DT_SINGLELINE | DT_VCENTER);
        SelectObject(hdc, old);
        EndPaint(hWnd, &ps);
        return 0;
    }
    case WM_DRAWITEM: {
        // Owner-draw button
        auto* dis = (DRAWITEMSTRUCT*)lParam;
        if (dis->CtlID != ID_BTN) break;
        HBRUSH bg = g_btnHover ? g_hHoverBrush : g_hBtnBrush;
        FillRect(dis->hDC, &dis->rcItem, bg);
        FrameRect(dis->hDC, &dis->rcItem, (HBRUSH)GetStockObject(GRAY_BRUSH));
        SetTextColor(dis->hDC, TEXT_COLOR);
        SetBkMode(dis->hDC, TRANSPARENT);
        HFONT old = (HFONT)SelectObject(dis->hDC, g_hFont);
        DrawTextW(dis->hDC, L"Click Me", -1, &dis->rcItem, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        SelectObject(dis->hDC, old);
        return TRUE;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_BTN)
            MessageBoxW(hWnd, L"Button clicked!", L"Dark Mode", MB_OK);
        return 0;
    case WM_MOUSEMOVE: {
        POINT pt = { LOWORD(lParam), HIWORD(lParam) };
        RECT btnRc = { 180, 140, 320, 176 };
        bool over = PtInRect(&btnRc, pt);
        if (over != g_btnHover) { g_btnHover = over; InvalidateRect(hWnd, &btnRc, FALSE); }
        return 0;
    }
    case WM_DESTROY:
        DeleteObject(g_hBgBrush); DeleteObject(g_hBtnBrush);
        DeleteObject(g_hHoverBrush); DeleteObject(g_hFont);
        PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int nShow) {
    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = L"DarkWnd";
    wc.hbrBackground = nullptr;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassExW(&wc);

    HWND hWnd = CreateWindowExW(0, L"DarkWnd", L"Dark Mode Window",
        WS_OVERLAPPEDWINDOW & ~WS_THICKFRAME & ~WS_MAXIMIZEBOX,
        CW_USEDEFAULT, CW_USEDEFAULT, 500, 320,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hWnd, nShow);
    UpdateWindow(hWnd);

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "dwmapi.lib;gdi32.lib;user32.lib",
    },

    "imgui_tool_panel": {
        "label": "ImGui Tool Panel (DX11)",
        "desc":  "ImGui app laid out as a practical tool: sidebar nav, main content area, status bar, and a log panel. Good starting point for any internal tool or cheat menu.",
        "cpp": '''\
// ─────────────────────────────────────────────────────────────────
//  ImGui Tool Panel — DX11 + Win32
//  Layout: sidebar | main content area + bottom log
//
//  SETUP: same as Dear ImGui DX11 template.
// ─────────────────────────────────────────────────────────────────
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <tchar.h>
#include <string>
#include <vector>
#include <deque>

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

// ── D3D globals ───────────────────────────────────────────────────
static ID3D11Device*           g_pd3dDevice        = nullptr;
static ID3D11DeviceContext*    g_pd3dDeviceContext  = nullptr;
static IDXGISwapChain*         g_pSwapChain         = nullptr;
static ID3D11RenderTargetView* g_mainRTV            = nullptr;

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND,UINT,WPARAM,LPARAM);

static bool CreateDeviceD3D(HWND);
static void CleanupDeviceD3D();
static void CreateRTV();
static void CleanupRTV();

LRESULT CALLBACK WndProc(HWND h, UINT m, WPARAM w, LPARAM l) {
    if (ImGui_ImplWin32_WndProcHandler(h, m, w, l)) return true;
    switch (m) {
    case WM_SIZE:
        if (w != SIZE_MINIMIZED) { CleanupRTV(); g_pSwapChain->ResizeBuffers(0,LOWORD(l),HIWORD(l),DXGI_FORMAT_UNKNOWN,0); CreateRTV(); }
        return 0;
    case WM_SYSCOMMAND: if ((w&0xfff0)==SC_KEYMENU) return 0; break;
    case WM_DESTROY: PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

// ── App state ────────────────────────────────────────────────────
static int  s_page     = 0;
static bool s_feature1 = false;
static bool s_feature2 = true;
static float s_speed   = 1.0f;
static float s_fov     = 90.0f;
static char  s_inputBuf[256] = {};
static std::deque<std::string> s_log;

static void Log(const std::string& msg) {
    s_log.push_back(msg);
    if (s_log.size() > 200) s_log.pop_front();
}

static void DrawSidebar() {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(0.10f, 0.10f, 0.13f, 1.f));
    ImGui::BeginChild("##sidebar", ImVec2(130, 0), false);

    ImGui::Spacing();
    ImGui::Indent(8.f);
    ImGui::TextColored(ImVec4(0.6f,0.8f,1.f,1.f), "TOOL PANEL");
    ImGui::Unindent(8.f);
    ImGui::Separator();
    ImGui::Spacing();

    const char* pages[] = { "Dashboard", "Settings", "Features", "About" };
    for (int i = 0; i < 4; ++i) {
        bool sel = (s_page == i);
        if (sel) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.2f,0.4f,0.8f,0.9f));
        if (ImGui::Button(pages[i], ImVec2(114, 30))) { s_page = i; Log(std::string("Switched to: ") + pages[i]); }
        if (sel) ImGui::PopStyleColor();
        ImGui::Spacing();
    }

    ImGui::EndChild();
    ImGui::PopStyleColor();
}

static void DrawContent() {
    ImGui::BeginChild("##content", ImVec2(0, -120), false);

    switch (s_page) {
    case 0: // Dashboard
        ImGui::TextColored(ImVec4(0.4f,1.f,0.6f,1.f), "Dashboard");
        ImGui::Separator(); ImGui::Spacing();
        ImGui::Text("Status: "); ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.3f,1.f,0.3f,1.f), "Running");
        ImGui::Spacing();
        ImGui::Text("Speed:  %.2f", s_speed);
        ImGui::Text("FOV:    %.1f", s_fov);
        ImGui::Text("Log entries: %d", (int)s_log.size());
        break;
    case 1: // Settings
        ImGui::TextColored(ImVec4(0.4f,1.f,0.6f,1.f), "Settings");
        ImGui::Separator(); ImGui::Spacing();
        ImGui::SliderFloat("Speed",  &s_speed, 0.1f, 10.f);
        ImGui::SliderFloat("FOV",    &s_fov,   60.f, 120.f);
        ImGui::InputText("Custom",  s_inputBuf, IM_ARRAYSIZE(s_inputBuf));
        if (ImGui::Button("Apply")) Log("Settings applied.");
        break;
    case 2: // Features
        ImGui::TextColored(ImVec4(0.4f,1.f,0.6f,1.f), "Features");
        ImGui::Separator(); ImGui::Spacing();
        if (ImGui::Checkbox("Feature One", &s_feature1)) Log(s_feature1 ? "Feature 1 ON" : "Feature 1 OFF");
        if (ImGui::Checkbox("Feature Two", &s_feature2)) Log(s_feature2 ? "Feature 2 ON" : "Feature 2 OFF");
        ImGui::Spacing();
        if (ImGui::Button("Run Action")) Log("Action triggered!");
        break;
    case 3: // About
        ImGui::TextColored(ImVec4(0.4f,1.f,0.6f,1.f), "About");
        ImGui::Separator(); ImGui::Spacing();
        ImGui::Text("Tool Panel Template");
        ImGui::Text("Built with Dear ImGui + DX11");
        ImGui::Text("Build Doctor C++ Creator");
        break;
    }

    ImGui::EndChild();
}

static void DrawLog() {
    ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(0.08f,0.08f,0.10f,1.f));
    ImGui::BeginChild("##log", ImVec2(0, 110), true);
    ImGui::TextColored(ImVec4(0.5f,0.5f,0.5f,1.f), "Log");
    ImGui::Separator();
    for (auto& line : s_log)
        ImGui::TextUnformatted(line.c_str());
    if (ImGui::GetScrollY() >= ImGui::GetScrollMaxY())
        ImGui::SetScrollHereY(1.f);
    ImGui::EndChild();
    ImGui::PopStyleColor();
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int) {
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0, 0,
        GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr, L"ToolPanel", nullptr };
    RegisterClassExW(&wc);
    HWND hwnd = CreateWindowW(wc.lpszClassName, L"Tool Panel",
        WS_OVERLAPPEDWINDOW, 100, 100, 960, 600, nullptr, nullptr, wc.hInstance, nullptr);

    if (!CreateDeviceD3D(hwnd)) { CleanupDeviceD3D(); return 1; }
    ShowWindow(hwnd, SW_SHOWDEFAULT); UpdateWindow(hwnd);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    ImGui::StyleColorsDark();

    // Tweak style for a tighter dark look
    ImGuiStyle& st = ImGui::GetStyle();
    st.WindowRounding    = 4.f; st.FrameRounding  = 3.f;
    st.ScrollbarRounding = 3.f; st.GrabRounding   = 3.f;
    st.WindowBorderSize  = 0.f; st.FrameBorderSize = 0.f;

    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

    Log("Tool Panel started.");

    ImVec4 clear = ImVec4(0.08f, 0.08f, 0.10f, 1.f);
    MSG msg = {};
    while (msg.message != WM_QUIT) {
        if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg); DispatchMessage(&msg); continue;
        }
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        // Full-screen window — no title bar, no padding
        ImGuiViewport* vp = ImGui::GetMainViewport();
        ImGui::SetNextWindowPos(vp->WorkPos);
        ImGui::SetNextWindowSize(vp->WorkSize);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0,0));
        ImGui::Begin("##root", nullptr,
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove     | ImGuiWindowFlags_NoBringToFrontOnFocus);
        ImGui::PopStyleVar();

        // Status bar at the top
        ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(0.13f,0.13f,0.16f,1.f));
        ImGui::BeginChild("##topbar", ImVec2(0, 28), false);
        ImGui::SetCursorPosY(5); ImGui::SetCursorPosX(8);
        ImGui::Text("Tool Panel  |  FPS: %.0f", io.Framerate);
        ImGui::EndChild();
        ImGui::PopStyleColor();

        // Sidebar + content side by side
        DrawSidebar();
        ImGui::SameLine(0, 0);
        ImGui::BeginChild("##right", ImVec2(0, 0), false);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(12, 10));
        DrawContent();
        DrawLog();
        ImGui::PopStyleVar();
        ImGui::EndChild();

        ImGui::End();

        ImGui::Render();
        const float cc[4] = { clear.x, clear.y, clear.z, clear.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRTV, nullptr);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRTV, cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_pSwapChain->Present(1, 0);
    }

    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
    CleanupDeviceD3D();
    DestroyWindow(hwnd);
    UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return 0;
}

static bool CreateDeviceD3D(HWND hWnd) {
    DXGI_SWAP_CHAIN_DESC sd = {};
    sd.BufferCount = 2; sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate = { 60, 1 }; sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT; sd.OutputWindow = hWnd;
    sd.SampleDesc = { 1, 0 }; sd.Windowed = TRUE; sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    const D3D_FEATURE_LEVEL fl[] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    D3D_FEATURE_LEVEL flOut;
    HRESULT hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
        fl, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &flOut, &g_pd3dDeviceContext);
    if (hr == DXGI_ERROR_UNSUPPORTED)
        hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, 0,
            fl, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &flOut, &g_pd3dDeviceContext);
    if (hr != S_OK) return false;
    CreateRTV(); return true;
}
static void CleanupDeviceD3D() {
    CleanupRTV();
    if (g_pSwapChain)       { g_pSwapChain->Release();       g_pSwapChain      = nullptr; }
    if (g_pd3dDeviceContext){ g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
    if (g_pd3dDevice)       { g_pd3dDevice->Release();       g_pd3dDevice       = nullptr; }
}
static void CreateRTV() {
    ID3D11Texture2D* pBack = nullptr;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBack));
    if (pBack) { g_pd3dDevice->CreateRenderTargetView(pBack, nullptr, &g_mainRTV); pBack->Release(); }
}
static void CleanupRTV() {
    if (g_mainRTV) { g_mainRTV->Release(); g_mainRTV = nullptr; }
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;user32.lib;gdi32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": (
            "ImGui setup required (same as DX11 template):\n"
            "  Create an 'imgui/' folder next to main.cpp and copy ImGui headers/sources into it.\n"
            "  See the Dear ImGui DX11 template for the full file list."
        ),
    },

    "imgui_overlay": {
        "label": "ImGui Transparent Overlay (DX11)",
        "desc":  "Borderless transparent always-on-top ImGui overlay window — typical starting point for external overlays and HUDs.",
        "cpp": '''\
// ─────────────────────────────────────────────────────────────────
//  ImGui Transparent Overlay — DX11 + Win32
//  Borderless, transparent, always-on-top, click-through toggle.
//
//  SETUP: same as Dear ImGui DX11 template.
//  Press INSERT to toggle click-through.
// ─────────────────────────────────────────────────────────────────
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <tchar.h>
#include <string>

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

static ID3D11Device*           g_pDevice   = nullptr;
static ID3D11DeviceContext*    g_pCtx      = nullptr;
static IDXGISwapChain*         g_pChain    = nullptr;
static ID3D11RenderTargetView* g_pRTV      = nullptr;
static bool                    g_clickThru = false;

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND,UINT,WPARAM,LPARAM);

static bool CreateDX(HWND hWnd);
static void CleanupDX();
static void CreateRTV();
static void CleanupRTV();

void SetClickThrough(HWND hWnd, bool enable) {
    LONG ex = GetWindowLong(hWnd, GWL_EXSTYLE);
    if (enable) ex |= WS_EX_TRANSPARENT;
    else        ex &= ~WS_EX_TRANSPARENT;
    SetWindowLong(hWnd, GWL_EXSTYLE, ex);
    g_clickThru = enable;
}

LRESULT CALLBACK WndProc(HWND h, UINT m, WPARAM w, LPARAM l) {
    if (ImGui_ImplWin32_WndProcHandler(h, m, w, l)) return true;
    switch (m) {
    case WM_SIZE:
        if (w != SIZE_MINIMIZED) { CleanupRTV(); g_pChain->ResizeBuffers(0,LOWORD(l),HIWORD(l),DXGI_FORMAT_UNKNOWN,0); CreateRTV(); }
        return 0;
    case WM_DESTROY: PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int) {
    // Full-screen overlay — match desktop size
    int sw = GetSystemMetrics(SM_CXSCREEN);
    int sh = GetSystemMetrics(SM_CYSCREEN);

    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0, 0,
        GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr, L"Overlay", nullptr };
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_LAYERED | WS_EX_TRANSPARENT,
        L"Overlay", L"Overlay",
        WS_POPUP, 0, 0, sw, sh,
        nullptr, nullptr, hInst, nullptr);

    // Transparent background via layered window
    SetLayeredWindowAttributes(hwnd, 0, 0, LWA_ALPHA);

    if (!CreateDX(hwnd)) { CleanupDX(); return 1; }
    ShowWindow(hwnd, SW_SHOWDEFAULT); UpdateWindow(hwnd);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    ImGui::StyleColorsDark();
    ImGui::GetStyle().WindowBorderSize = 1.f;

    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pDevice, g_pCtx);

    // State
    bool  show_menu  = true;
    float esp_dist   = 200.f;
    bool  esp_boxes  = true;
    bool  esp_names  = false;
    int   esp_color  = 0; // 0=green 1=red 2=white

    MSG msg = {};
    while (msg.message != WM_QUIT) {
        if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg); DispatchMessage(&msg); continue;
        }

        // INSERT toggles click-through
        if (GetAsyncKeyState(VK_INSERT) & 1)
            SetClickThrough(hwnd, !g_clickThru);
        // END closes overlay
        if (GetAsyncKeyState(VK_END) & 1)
            PostQuitMessage(0);

        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        // ── Main menu window ──────────────────────────────────────
        if (show_menu) {
            ImGui::SetNextWindowPos(ImVec2(20, 20), ImGuiCond_Once);
            ImGui::SetNextWindowSize(ImVec2(300, 220), ImGuiCond_Once);
            ImGui::SetNextWindowBgAlpha(0.88f);
            ImGui::Begin("Overlay Menu  [INSERT = click-through]", &show_menu);

            ImGui::Text("Status: %s", g_clickThru ? "Click-through ON" : "Interactive");
            ImGui::Separator();

            ImGui::Checkbox("ESP Boxes",  &esp_boxes);
            ImGui::Checkbox("ESP Names",  &esp_names);
            ImGui::SliderFloat("Max Dist", &esp_dist, 50.f, 500.f);

            const char* colors[] = { "Green", "Red", "White" };
            ImGui::Combo("Color", &esp_color, colors, 3);

            ImGui::Separator();
            ImGui::TextColored(ImVec4(0.5f,0.5f,0.5f,1.f), "END = quit overlay");
            ImGui::End();
        }

        // ── ESP draw example (screen-space) ───────────────────────
        ImDrawList* dl = ImGui::GetBackgroundDrawList();
        if (esp_boxes) {
            ImVec4 c4 = esp_color==0 ? ImVec4(0,1,0,1) : esp_color==1 ? ImVec4(1,0,0,1) : ImVec4(1,1,1,1);
            ImU32 col = ImGui::ColorConvertFloat4ToU32(c4);
            // Demo box — replace with real entity positions
            dl->AddRect(ImVec2(600,200), ImVec2(660,350), col, 0, 0, 1.5f);
            if (esp_names)
                dl->AddText(ImVec2(605, 193), col, "Entity");
        }

        // Crosshair
        dl->AddLine(ImVec2(sw/2.f-10,sh/2.f), ImVec2(sw/2.f+10,sh/2.f), IM_COL32(255,255,255,180), 1.f);
        dl->AddLine(ImVec2(sw/2.f,sh/2.f-10), ImVec2(sw/2.f,sh/2.f+10), IM_COL32(255,255,255,180), 1.f);

        ImGui::Render();

        // Clear to fully transparent
        const float cc[4] = { 0,0,0,0 };
        g_pCtx->OMSetRenderTargets(1, &g_pRTV, nullptr);
        g_pCtx->ClearRenderTargetView(g_pRTV, cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_pChain->Present(1, 0);
    }

    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
    CleanupDX();
    DestroyWindow(hwnd);
    UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return 0;
}

static bool CreateDX(HWND hWnd) {
    DXGI_SWAP_CHAIN_DESC sd = {};
    sd.BufferCount = 2; sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate = { 60, 1 };
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT; sd.OutputWindow = hWnd;
    sd.SampleDesc = { 1, 0 }; sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    const D3D_FEATURE_LEVEL fl[] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    D3D_FEATURE_LEVEL flOut;
    HRESULT hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
        fl, 2, D3D11_SDK_VERSION, &sd, &g_pChain, &g_pDevice, &flOut, &g_pCtx);
    if (hr == DXGI_ERROR_UNSUPPORTED)
        hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, 0,
            fl, 2, D3D11_SDK_VERSION, &sd, &g_pChain, &g_pDevice, &flOut, &g_pCtx);
    if (hr != S_OK) return false;
    CreateRTV(); return true;
}
static void CleanupDX() {
    CleanupRTV();
    if (g_pChain)  { g_pChain->Release();  g_pChain  = nullptr; }
    if (g_pCtx)    { g_pCtx->Release();    g_pCtx    = nullptr; }
    if (g_pDevice) { g_pDevice->Release(); g_pDevice = nullptr; }
}
static void CreateRTV() {
    ID3D11Texture2D* pB = nullptr;
    g_pChain->GetBuffer(0, IID_PPV_ARGS(&pB));
    if (pB) { g_pDevice->CreateRenderTargetView(pB, nullptr, &g_pRTV); pB->Release(); }
}
static void CleanupRTV() {
    if (g_pRTV) { g_pRTV->Release(); g_pRTV = nullptr; }
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;user32.lib;gdi32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": (
            "ImGui setup required (same as DX11 template).\n"
            "Press INSERT in-game to toggle click-through mode.\n"
            "Press END to close the overlay."
        ),
    },

    "win32_tray_app": {
        "label": "Win32 System Tray App",
        "desc":  "Minimal app that lives in the system tray with a right-click context menu. No visible window on launch — common pattern for background tools.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include <string>

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "user32.lib")

#define WM_TRAYICON  (WM_USER + 1)
#define ID_TRAY_ICON  1
#define IDM_SHOW      101
#define IDM_ABOUT     102
#define IDM_EXIT      103

static NOTIFYICONDATAW g_nid = {};
static HWND            g_hWnd = nullptr;

void AddTrayIcon(HWND hWnd) {
    g_nid.cbSize           = sizeof(g_nid);
    g_nid.hWnd             = hWnd;
    g_nid.uID              = ID_TRAY_ICON;
    g_nid.uFlags           = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;
    g_nid.hIcon            = LoadIcon(nullptr, IDI_APPLICATION);
    wcscpy_s(g_nid.szTip, L"My Tray App");
    Shell_NotifyIconW(NIM_ADD, &g_nid);
}

void RemoveTrayIcon() {
    Shell_NotifyIconW(NIM_DELETE, &g_nid);
}

void ShowTrayMenu(HWND hWnd) {
    POINT pt; GetCursorPos(&pt);
    HMENU hMenu = CreatePopupMenu();
    AppendMenuW(hMenu, MF_STRING, IDM_SHOW,  L"Show Window");
    AppendMenuW(hMenu, MF_STRING, IDM_ABOUT, L"About");
    AppendMenuW(hMenu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(hMenu, MF_STRING, IDM_EXIT,  L"Exit");

    SetForegroundWindow(hWnd);
    TrackPopupMenu(hMenu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hWnd, nullptr);
    DestroyMenu(hMenu);
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        AddTrayIcon(hWnd);
        return 0;

    case WM_TRAYICON:
        if (LOWORD(lParam) == WM_RBUTTONUP)
            ShowTrayMenu(hWnd);
        else if (LOWORD(lParam) == WM_LBUTTONDBLCLK)
            ShowWindow(hWnd, SW_SHOW);
        return 0;

    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_SHOW:
            ShowWindow(hWnd, SW_SHOW);
            SetForegroundWindow(hWnd);
            break;
        case IDM_ABOUT:
            MessageBoxW(hWnd, L"Tray App Template\nBuild Doctor C++ Creator",
                        L"About", MB_OK | MB_ICONINFORMATION);
            break;
        case IDM_EXIT:
            DestroyWindow(hWnd);
            break;
        }
        return 0;

    case WM_CLOSE:
        // Hide to tray instead of closing
        ShowWindow(hWnd, SW_HIDE);
        return 0;

    case WM_DESTROY:
        RemoveTrayIcon();
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int) {
    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = L"TrayApp";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassExW(&wc);

    g_hWnd = CreateWindowExW(0, L"TrayApp", L"Tray App",
        WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX & ~WS_THICKFRAME,
        CW_USEDEFAULT, CW_USEDEFAULT, 400, 250,
        nullptr, nullptr, hInst, nullptr);

    // Start hidden in tray
    // ShowWindow(g_hWnd, SW_SHOW);  // uncomment to show on launch

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "shell32.lib;user32.lib",
    },

    "win32_gdi_paint": {
        "label": "Win32 GDI Canvas (Drawing)",
        "desc":  "Win32 window with double-buffered GDI — draws shapes, gradient, and text on every frame. Good base for 2D tools and visualizers.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cmath>
#include <string>

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

static int   g_w = 800, g_h = 600;
static float g_t = 0.f;   // animation time

void DrawScene(HDC hdc) {
    // Background gradient
    for (int y = 0; y < g_h; ++y) {
        float t = (float)y / g_h;
        int r = (int)(15  + t * 20);
        int g = (int)(15  + t * 15);
        int b = (int)(30  + t * 40);
        HPEN p = CreatePen(PS_SOLID, 1, RGB(r, g, b));
        HPEN old = (HPEN)SelectObject(hdc, p);
        MoveToEx(hdc, 0, y, nullptr);
        LineTo(hdc, g_w, y);
        SelectObject(hdc, old);
        DeleteObject(p);
    }

    // Animated circle
    float cx = g_w / 2.f + cosf(g_t) * 120.f;
    float cy = g_h / 2.f + sinf(g_t) * 80.f;
    HBRUSH br = CreateSolidBrush(RGB(80, 180, 255));
    HPEN   pn = CreatePen(PS_SOLID, 2, RGB(120, 220, 255));
    HBRUSH old_br = (HBRUSH)SelectObject(hdc, br);
    HPEN   old_pn = (HPEN)SelectObject(hdc, pn);
    Ellipse(hdc, (int)(cx-40), (int)(cy-40), (int)(cx+40), (int)(cy+40));
    SelectObject(hdc, old_br); SelectObject(hdc, old_pn);
    DeleteObject(br); DeleteObject(pn);

    // Grid lines
    HPEN gridPen = CreatePen(PS_SOLID, 1, RGB(40, 40, 55));
    SelectObject(hdc, gridPen);
    for (int x = 0; x < g_w; x += 40) { MoveToEx(hdc,x,0,nullptr); LineTo(hdc,x,g_h); }
    for (int y = 0; y < g_h; y += 40) { MoveToEx(hdc,0,y,nullptr); LineTo(hdc,g_w,y); }
    SelectObject(hdc, (HPEN)GetStockObject(BLACK_PEN));
    DeleteObject(gridPen);

    // Text overlay
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, RGB(220, 220, 220));
    HFONT hFont = CreateFontW(22, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Segoe UI");
    HFONT oldF = (HFONT)SelectObject(hdc, hFont);
    std::wstring txt = L"GDI Canvas  t=" + std::to_wstring((int)(g_t*10)/10.f);
    TextOutW(hdc, 12, 12, txt.c_str(), (int)txt.size());
    SelectObject(hdc, oldF); DeleteObject(hFont);
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_SIZE:
        g_w = LOWORD(lParam); g_h = HIWORD(lParam);
        return 0;
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        // Double-buffered paint
        HDC  memDC  = CreateCompatibleDC(hdc);
        HBITMAP bmp = CreateCompatibleBitmap(hdc, g_w, g_h);
        HBITMAP old = (HBITMAP)SelectObject(memDC, bmp);
        DrawScene(memDC);
        BitBlt(hdc, 0, 0, g_w, g_h, memDC, 0, 0, SRCCOPY);
        SelectObject(memDC, old);
        DeleteObject(bmp); DeleteDC(memDC);
        EndPaint(hWnd, &ps);
        return 0;
    }
    case WM_TIMER:
        g_t += 0.033f;
        InvalidateRect(hWnd, nullptr, FALSE);
        return 0;
    case WM_DESTROY:
        KillTimer(hWnd, 1);
        PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(hWnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int nShow) {
    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = L"GDICanvas";
    wc.hbrBackground = nullptr;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassExW(&wc);

    HWND hWnd = CreateWindowExW(0, L"GDICanvas", L"GDI Canvas",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hWnd, nShow);
    UpdateWindow(hWnd);
    SetTimer(hWnd, 1, 16, nullptr); // ~60 fps

    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "gdi32.lib;user32.lib",
    },

    "process_manager": {
        "label": "Process Manager GUI (ImGui DX11)",
        "desc":  "Lists running processes with PID, memory, and CPU. Kill button per row. Good base for any process tool.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>
#include <d3d11.h>
#include <string>
#include <vector>
#include <algorithm>
#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"
#pragma comment(lib,"d3d11.lib") #pragma comment(lib,"dxgi.lib") #pragma comment(lib,"psapi.lib")

static ID3D11Device*           g_pDev  = nullptr;
static ID3D11DeviceContext*    g_pCtx  = nullptr;
static IDXGISwapChain*         g_pChain= nullptr;
static ID3D11RenderTargetView* g_pRTV  = nullptr;
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND,UINT,WPARAM,LPARAM);

struct ProcInfo { DWORD pid; std::string name; SIZE_T memKB; };

static std::vector<ProcInfo> g_procs;
static char g_filter[128] = {};
static std::string g_status;

void RefreshProcs() {
    g_procs.clear();
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return;
    PROCESSENTRY32W pe = { sizeof(pe) };
    if (Process32FirstW(snap, &pe)) {
        do {
            ProcInfo info;
            info.pid  = pe.th32ProcessID;
            char buf[MAX_PATH] = {};
            WideCharToMultiByte(CP_UTF8,0,pe.szExeFile,-1,buf,MAX_PATH,nullptr,nullptr);
            info.name = buf;
            info.memKB = 0;
            HANDLE hProc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pe.th32ProcessID);
            if (hProc) {
                PROCESS_MEMORY_COUNTERS pmc = {};
                if (GetProcessMemoryInfo(hProc,(PROCESS_MEMORY_COUNTERS*)&pmc,sizeof(pmc)))
                    info.memKB = pmc.WorkingSetSize / 1024;
                CloseHandle(hProc);
            }
            g_procs.push_back(info);
        } while (Process32NextW(snap, &pe));
    }
    CloseHandle(snap);
    std::sort(g_procs.begin(), g_procs.end(), [](auto& a, auto& b){ return a.name < b.name; });
    g_status = "Refreshed — " + std::to_string(g_procs.size()) + " processes";
}

static bool CreateDX(HWND h);
static void CleanupDX();
static void CreateRTV();
static void CleanupRTV();

LRESULT CALLBACK WndProc(HWND h,UINT m,WPARAM w,LPARAM l){
    if(ImGui_ImplWin32_WndProcHandler(h,m,w,l)) return true;
    switch(m){
    case WM_SIZE: if(w!=SIZE_MINIMIZED){CleanupRTV();g_pChain->ResizeBuffers(0,LOWORD(l),HIWORD(l),DXGI_FORMAT_UNKNOWN,0);CreateRTV();}return 0;
    case WM_DESTROY: PostQuitMessage(0);return 0;
    } return DefWindowProcW(h,m,w,l);
}

int WINAPI WinMain(HINSTANCE hI,HINSTANCE,LPSTR,int){
    WNDCLASSEXW wc={sizeof(wc),CS_CLASSDC,WndProc,0,0,GetModuleHandle(nullptr),nullptr,nullptr,nullptr,nullptr,L"ProcMgr",nullptr};
    RegisterClassExW(&wc);
    HWND hwnd=CreateWindowW(wc.lpszClassName,L"Process Manager",WS_OVERLAPPEDWINDOW,100,100,900,600,nullptr,nullptr,wc.hInstance,nullptr);
    if(!CreateDX(hwnd)){CleanupDX();return 1;}
    ShowWindow(hwnd,SW_SHOWDEFAULT); UpdateWindow(hwnd);
    IMGUI_CHECKVERSION(); ImGui::CreateContext();
    ImGui::StyleColorsDark();
    ImGui_ImplWin32_Init(hwnd); ImGui_ImplDX11_Init(g_pDev,g_pCtx);
    RefreshProcs();
    MSG msg={};
    while(msg.message!=WM_QUIT){
        if(PeekMessage(&msg,nullptr,0,0,PM_REMOVE)){TranslateMessage(&msg);DispatchMessage(&msg);continue;}
        ImGui_ImplDX11_NewFrame(); ImGui_ImplWin32_NewFrame(); ImGui::NewFrame();

        ImGuiViewport* vp=ImGui::GetMainViewport();
        ImGui::SetNextWindowPos(vp->WorkPos); ImGui::SetNextWindowSize(vp->WorkSize);
        ImGui::Begin("##pm",nullptr,ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize|ImGuiWindowFlags_NoMove);

        if(ImGui::Button("Refresh")) RefreshProcs();
        ImGui::SameLine(); ImGui::SetNextItemWidth(300);
        ImGui::InputText("Filter##f",g_filter,sizeof(g_filter));
        ImGui::SameLine(); ImGui::TextDisabled("%s",g_status.c_str());

        ImGui::Separator();
        if(ImGui::BeginTable("procs",4,ImGuiTableFlags_ScrollY|ImGuiTableFlags_RowBg|ImGuiTableFlags_BordersOuter|ImGuiTableFlags_BordersInnerV|ImGuiTableFlags_Sortable,ImVec2(0,-30))){
            ImGui::TableSetupScrollFreeze(0,1);
            ImGui::TableSetupColumn("PID",   ImGuiTableColumnFlags_WidthFixed,70);
            ImGui::TableSetupColumn("Name",  ImGuiTableColumnFlags_WidthStretch);
            ImGui::TableSetupColumn("Mem KB",ImGuiTableColumnFlags_WidthFixed,90);
            ImGui::TableSetupColumn("Action",ImGuiTableColumnFlags_WidthFixed,80);
            ImGui::TableHeadersRow();
            std::string flt(g_filter);
            for(auto& p : g_procs){
                if(!flt.empty() && p.name.find(flt)==std::string::npos) continue;
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0); ImGui::Text("%lu",p.pid);
                ImGui::TableSetColumnIndex(1); ImGui::TextUnformatted(p.name.c_str());
                ImGui::TableSetColumnIndex(2); ImGui::Text("%zu",p.memKB);
                ImGui::TableSetColumnIndex(3);
                ImGui::PushID((int)p.pid);
                if(ImGui::SmallButton("Kill")){
                    HANDLE h=OpenProcess(PROCESS_TERMINATE,FALSE,p.pid);
                    if(h){TerminateProcess(h,1);CloseHandle(h);g_status="Killed PID "+std::to_string(p.pid);RefreshProcs();}
                    else g_status="Access denied PID "+std::to_string(p.pid);
                }
                ImGui::PopID();
            }
            ImGui::EndTable();
        }
        ImGui::TextDisabled("Double-click a row to inspect (extend me!)");
        ImGui::End();

        ImGui::Render();
        const float cc[4]={0.08f,0.08f,0.1f,1.f};
        g_pCtx->OMSetRenderTargets(1,&g_pRTV,nullptr);
        g_pCtx->ClearRenderTargetView(g_pRTV,cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_pChain->Present(1,0);
    }
    ImGui_ImplDX11_Shutdown(); ImGui_ImplWin32_Shutdown(); ImGui::DestroyContext();
    CleanupDX(); DestroyWindow(hwnd); UnregisterClassW(wc.lpszClassName,wc.hInstance);
    return 0;
}
static bool CreateDX(HWND h){DXGI_SWAP_CHAIN_DESC sd={};sd.BufferCount=2;sd.BufferDesc.Format=DXGI_FORMAT_R8G8B8A8_UNORM;sd.BufferDesc.RefreshRate={60,1};sd.Flags=DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;sd.BufferUsage=DXGI_USAGE_RENDER_TARGET_OUTPUT;sd.OutputWindow=h;sd.SampleDesc={1,0};sd.Windowed=TRUE;sd.SwapEffect=DXGI_SWAP_EFFECT_DISCARD;const D3D_FEATURE_LEVEL fl[]={D3D_FEATURE_LEVEL_11_0,D3D_FEATURE_LEVEL_10_0};D3D_FEATURE_LEVEL fo;HRESULT hr=D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_HARDWARE,nullptr,0,fl,2,D3D11_SDK_VERSION,&sd,&g_pChain,&g_pDev,&fo,&g_pCtx);if(hr==DXGI_ERROR_UNSUPPORTED)hr=D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_WARP,nullptr,0,fl,2,D3D11_SDK_VERSION,&sd,&g_pChain,&g_pDev,&fo,&g_pCtx);if(hr!=S_OK)return false;CreateRTV();return true;}
static void CleanupDX(){CleanupRTV();if(g_pChain){g_pChain->Release();g_pChain=nullptr;}if(g_pCtx){g_pCtx->Release();g_pCtx=nullptr;}if(g_pDev){g_pDev->Release();g_pDev=nullptr;}}
static void CreateRTV(){ID3D11Texture2D*p=nullptr;g_pChain->GetBuffer(0,IID_PPV_ARGS(&p));if(p){g_pDev->CreateRenderTargetView(p,nullptr,&g_pRTV);p->Release();}}
static void CleanupRTV(){if(g_pRTV){g_pRTV->Release();g_pRTV=nullptr;}}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;psapi.lib;user32.lib;gdi32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": "ImGui setup required — same as Dear ImGui DX11 template.",
    },

    "sysinfo_dashboard": {
        "label": "System Info Dashboard (ImGui DX11)",
        "desc":  "Live CPU load, RAM usage, disk space, and uptime displayed in an ImGui dashboard.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <string>
#include <deque>
#include <pdh.h>
#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"
#pragma comment(lib,"d3d11.lib") #pragma comment(lib,"dxgi.lib") #pragma comment(lib,"pdh.lib")

static ID3D11Device*           g_pDev  = nullptr;
static ID3D11DeviceContext*    g_pCtx  = nullptr;
static IDXGISwapChain*         g_pChain= nullptr;
static ID3D11RenderTargetView* g_pRTV  = nullptr;

static PDH_HQUERY  g_cpuQuery  = nullptr;
static PDH_HCOUNTER g_cpuCtr   = nullptr;
static std::deque<float> g_cpuHistory;
static constexpr int HIST = 120;

void InitPDH(){
    PdhOpenQuery(nullptr,0,&g_cpuQuery);
    PdhAddEnglishCounterW(g_cpuQuery,L"\\Processor(_Total)\\% Processor Time",0,&g_cpuCtr);
    PdhCollectQueryData(g_cpuQuery);
}
float GetCPU(){
    if(!g_cpuQuery) return 0.f;
    PdhCollectQueryData(g_cpuQuery);
    PDH_FMT_COUNTERVALUE val;
    PdhGetFormattedCounterValue(g_cpuCtr,PDH_FMT_DOUBLE,nullptr,&val);
    return (float)val.doubleValue;
}
std::string FmtBytes(DWORDLONG b){
    if(b>1024ULL*1024*1024) return std::to_string(b/1024/1024/1024)+" GB";
    if(b>1024*1024) return std::to_string(b/1024/1024)+" MB";
    return std::to_string(b/1024)+" KB";
}

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND,UINT,WPARAM,LPARAM);
static bool CreateDX(HWND h);static void CleanupDX();static void CreateRTV();static void CleanupRTV();

LRESULT CALLBACK WndProc(HWND h,UINT m,WPARAM w,LPARAM l){
    if(ImGui_ImplWin32_WndProcHandler(h,m,w,l))return true;
    switch(m){case WM_SIZE:if(w!=SIZE_MINIMIZED){CleanupRTV();g_pChain->ResizeBuffers(0,LOWORD(l),HIWORD(l),DXGI_FORMAT_UNKNOWN,0);CreateRTV();}return 0;case WM_DESTROY:PostQuitMessage(0);return 0;}
    return DefWindowProcW(h,m,w,l);
}

int WINAPI WinMain(HINSTANCE hI,HINSTANCE,LPSTR,int){
    WNDCLASSEXW wc={sizeof(wc),CS_CLASSDC,WndProc,0,0,GetModuleHandle(nullptr),nullptr,nullptr,nullptr,nullptr,L"SysInfo",nullptr};
    RegisterClassExW(&wc);
    HWND hwnd=CreateWindowW(wc.lpszClassName,L"System Dashboard",WS_OVERLAPPEDWINDOW,100,100,900,560,nullptr,nullptr,wc.hInstance,nullptr);
    if(!CreateDX(hwnd)){CleanupDX();return 1;}
    ShowWindow(hwnd,SW_SHOWDEFAULT);UpdateWindow(hwnd);
    IMGUI_CHECKVERSION();ImGui::CreateContext();
    ImGui::StyleColorsDark();
    ImGui_ImplWin32_Init(hwnd);ImGui_ImplDX11_Init(g_pDev,g_pCtx);
    InitPDH();
    float tickAcc=0.f;
    MSG msg={};
    while(msg.message!=WM_QUIT){
        if(PeekMessage(&msg,nullptr,0,0,PM_REMOVE)){TranslateMessage(&msg);DispatchMessage(&msg);continue;}
        ImGui_ImplDX11_NewFrame();ImGui_ImplWin32_NewFrame();ImGui::NewFrame();
        ImGuiIO& io=ImGui::GetIO();
        tickAcc+=io.DeltaTime;
        if(tickAcc>0.5f){tickAcc=0.f;float c=GetCPU();g_cpuHistory.push_back(c);if((int)g_cpuHistory.size()>HIST)g_cpuHistory.pop_front();}

        ImGuiViewport* vp=ImGui::GetMainViewport();
        ImGui::SetNextWindowPos(vp->WorkPos);ImGui::SetNextWindowSize(vp->WorkSize);
        ImGui::Begin("##si",nullptr,ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize|ImGuiWindowFlags_NoMove);
        ImGui::TextColored(ImVec4(0.4f,1.f,0.6f,1.f),"System Dashboard"); ImGui::Separator(); ImGui::Spacing();

        // CPU
        float cpuNow=g_cpuHistory.empty()?0.f:g_cpuHistory.back();
        ImGui::Text("CPU  %.1f%%",cpuNow);
        if(!g_cpuHistory.empty()){
            std::vector<float> v(g_cpuHistory.begin(),g_cpuHistory.end());
            ImGui::PlotLines("##cpu",v.data(),(int)v.size(),0,nullptr,0.f,100.f,ImVec2(0,60));
        }
        ImGui::Spacing();

        // RAM
        MEMORYSTATUSEX ms={sizeof(ms)};GlobalMemoryStatusEx(&ms);
        float ramUsed=(float)(ms.ullTotalPhys-ms.ullAvailPhys)/(float)ms.ullTotalPhys*100.f;
        ImGui::Text("RAM  %.1f%%  used  (%s / %s)",ramUsed,FmtBytes(ms.ullTotalPhys-ms.ullAvailPhys).c_str(),FmtBytes(ms.ullTotalPhys).c_str());
        ImGui::ProgressBar(ramUsed/100.f,ImVec2(-1,8),"");
        ImGui::Spacing();

        // Disk C:
        ULARGE_INTEGER free64,total64;
        if(GetDiskFreeSpaceExW(L"C:\\",&free64,&total64,nullptr)){
            float diskUsed=1.f-(float)free64.QuadPart/(float)total64.QuadPart;
            ImGui::Text("Disk C:  %.1f%%  used  (%s free / %s)",diskUsed*100.f,FmtBytes(free64.QuadPart).c_str(),FmtBytes(total64.QuadPart).c_str());
            ImGui::ProgressBar(diskUsed,ImVec2(-1,8),"");
        }
        ImGui::Spacing();

        // Uptime
        DWORD up=GetTickCount()/1000;
        ImGui::Text("Uptime  %02lu:%02lu:%02lu",up/3600,(up%3600)/60,up%60);
        ImGui::Spacing(); ImGui::Separator();
        ImGui::TextDisabled("FPS %.0f",io.Framerate);
        ImGui::End();

        ImGui::Render();
        const float cc[4]={0.08f,0.08f,0.1f,1.f};
        g_pCtx->OMSetRenderTargets(1,&g_pRTV,nullptr);
        g_pCtx->ClearRenderTargetView(g_pRTV,cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_pChain->Present(1,0);
    }
    ImGui_ImplDX11_Shutdown();ImGui_ImplWin32_Shutdown();ImGui::DestroyContext();
    if(g_cpuQuery)PdhCloseQuery(g_cpuQuery);
    CleanupDX();DestroyWindow(hwnd);UnregisterClassW(wc.lpszClassName,wc.hInstance);
    return 0;
}
static bool CreateDX(HWND h){DXGI_SWAP_CHAIN_DESC sd={};sd.BufferCount=2;sd.BufferDesc.Format=DXGI_FORMAT_R8G8B8A8_UNORM;sd.BufferDesc.RefreshRate={60,1};sd.Flags=DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;sd.BufferUsage=DXGI_USAGE_RENDER_TARGET_OUTPUT;sd.OutputWindow=h;sd.SampleDesc={1,0};sd.Windowed=TRUE;sd.SwapEffect=DXGI_SWAP_EFFECT_DISCARD;const D3D_FEATURE_LEVEL fl[]={D3D_FEATURE_LEVEL_11_0,D3D_FEATURE_LEVEL_10_0};D3D_FEATURE_LEVEL fo;HRESULT hr=D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_HARDWARE,nullptr,0,fl,2,D3D11_SDK_VERSION,&sd,&g_pChain,&g_pDev,&fo,&g_pCtx);if(hr==DXGI_ERROR_UNSUPPORTED)hr=D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_WARP,nullptr,0,fl,2,D3D11_SDK_VERSION,&sd,&g_pChain,&g_pDev,&fo,&g_pCtx);if(hr!=S_OK)return false;CreateRTV();return true;}
static void CleanupDX(){CleanupRTV();if(g_pChain){g_pChain->Release();g_pChain=nullptr;}if(g_pCtx){g_pCtx->Release();g_pCtx=nullptr;}if(g_pDev){g_pDev->Release();g_pDev=nullptr;}}
static void CreateRTV(){ID3D11Texture2D*p=nullptr;g_pChain->GetBuffer(0,IID_PPV_ARGS(&p));if(p){g_pDev->CreateRenderTargetView(p,nullptr,&g_pRTV);p->Release();}}
static void CleanupRTV(){if(g_pRTV){g_pRTV->Release();g_pRTV=nullptr;}}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;pdh.lib;user32.lib;gdi32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": "ImGui setup required — same as Dear ImGui DX11 template.",
    },

    "hotkey_manager": {
        "label": "Global Hotkey Manager (ImGui DX11)",
        "desc":  "Register global hotkeys, bind actions to them, and log activations. Good base for macro tools and automation.",
        "cpp": '''\
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <string>
#include <vector>
#include <deque>
#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_win32.h"
#include "imgui/backends/imgui_impl_dx11.h"
#pragma comment(lib,"d3d11.lib") #pragma comment(lib,"dxgi.lib")

static ID3D11Device*           g_pDev  = nullptr;
static ID3D11DeviceContext*    g_pCtx  = nullptr;
static IDXGISwapChain*         g_pChain= nullptr;
static ID3D11RenderTargetView* g_pRTV  = nullptr;

struct HotkeyEntry {
    int  id;
    UINT modifiers;   // MOD_ALT, MOD_CTRL, MOD_SHIFT, MOD_WIN
    UINT vk;
    std::string label;
    std::string action;
    bool active;
};

static std::vector<HotkeyEntry> g_hotkeys;
static std::deque<std::string>  g_log;
static int g_nextId = 100;
static char g_newLabel[64]  = "My Hotkey";
static char g_newAction[128]= "notepad.exe";
static bool g_newCtrl=false, g_newAlt=true, g_newShift=false;
static int  g_newVK = 'A';
static HWND g_hwnd  = nullptr;

void Log(const std::string& s){ g_log.push_front(s); if(g_log.size()>100)g_log.pop_back(); }

bool RegisterHotkey(HotkeyEntry& e){
    if(RegisterHotKey(g_hwnd,e.id,e.modifiers,e.vk)){ e.active=true; Log("[+] Registered: "+e.label); return true; }
    Log("[!] Failed to register: "+e.label+" (already taken?)"); return false;
}
void UnregisterHotkey(HotkeyEntry& e){ UnregisterHotKey(g_hwnd,e.id); e.active=false; Log("[-] Unregistered: "+e.label); }

std::string VKName(UINT vk){ char buf[32]; GetKeyNameTextA(MapVirtualKeyA(vk,MAPVK_VK_TO_VSC)<<16,buf,32); return buf; }

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND,UINT,WPARAM,LPARAM);
static bool CreateDX(HWND h);static void CleanupDX();static void CreateRTV();static void CleanupRTV();

LRESULT CALLBACK WndProc(HWND h,UINT m,WPARAM w,LPARAM l){
    if(ImGui_ImplWin32_WndProcHandler(h,m,w,l))return true;
    switch(m){
    case WM_HOTKEY:{
        int id=(int)w;
        for(auto& e:g_hotkeys) if(e.id==id){ Log("[HOTKEY] "+e.label+" → "+e.action); ShellExecuteA(nullptr,"open",e.action.c_str(),nullptr,nullptr,SW_SHOW); }
        return 0;
    }
    case WM_SIZE:if(w!=SIZE_MINIMIZED){CleanupRTV();g_pChain->ResizeBuffers(0,LOWORD(l),HIWORD(l),DXGI_FORMAT_UNKNOWN,0);CreateRTV();}return 0;
    case WM_DESTROY:for(auto& e:g_hotkeys)if(e.active)UnregisterHotKey(h,e.id);PostQuitMessage(0);return 0;
    }return DefWindowProcW(h,m,w,l);
}

int WINAPI WinMain(HINSTANCE hI,HINSTANCE,LPSTR,int){
    WNDCLASSEXW wc={sizeof(wc),CS_CLASSDC,WndProc,0,0,GetModuleHandle(nullptr),nullptr,nullptr,nullptr,nullptr,L"HkMgr",nullptr};
    RegisterClassExW(&wc);
    g_hwnd=CreateWindowW(wc.lpszClassName,L"Hotkey Manager",WS_OVERLAPPEDWINDOW,100,100,800,560,nullptr,nullptr,wc.hInstance,nullptr);
    if(!CreateDX(g_hwnd)){CleanupDX();return 1;}
    ShowWindow(g_hwnd,SW_SHOWDEFAULT);UpdateWindow(g_hwnd);
    IMGUI_CHECKVERSION();ImGui::CreateContext();ImGui::StyleColorsDark();
    ImGui_ImplWin32_Init(g_hwnd);ImGui_ImplDX11_Init(g_pDev,g_pCtx);
    MSG msg={};
    while(msg.message!=WM_QUIT){
        if(PeekMessage(&msg,nullptr,0,0,PM_REMOVE)){TranslateMessage(&msg);DispatchMessage(&msg);continue;}
        ImGui_ImplDX11_NewFrame();ImGui_ImplWin32_NewFrame();ImGui::NewFrame();
        ImGuiViewport* vp=ImGui::GetMainViewport();
        ImGui::SetNextWindowPos(vp->WorkPos);ImGui::SetNextWindowSize(vp->WorkSize);
        ImGui::Begin("##hk",nullptr,ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize|ImGuiWindowFlags_NoMove);
        ImGui::TextColored(ImVec4(0.4f,1.f,0.6f,1.f),"Global Hotkey Manager");ImGui::Separator();ImGui::Spacing();

        // Add new
        ImGui::Text("Add Hotkey"); ImGui::SameLine();
        ImGui::Checkbox("Ctrl",&g_newCtrl);ImGui::SameLine();
        ImGui::Checkbox("Alt",&g_newAlt);ImGui::SameLine();
        ImGui::Checkbox("Shift",&g_newShift);
        ImGui::SetNextItemWidth(120);ImGui::InputText("Label",g_newLabel,sizeof(g_newLabel));ImGui::SameLine();
        ImGui::SetNextItemWidth(200);ImGui::InputText("Action (exe/url)",g_newAction,sizeof(g_newAction));ImGui::SameLine();
        ImGui::SetNextItemWidth(60);
        char vkBuf[8]={(char)g_newVK,0};
        if(ImGui::InputText("Key",vkBuf,sizeof(vkBuf)) && vkBuf[0]) g_newVK=toupper(vkBuf[0]);
        ImGui::SameLine();
        if(ImGui::Button("Add")){
            HotkeyEntry e;
            e.id=g_nextId++;
            e.modifiers=(g_newCtrl?MOD_CONTROL:0)|(g_newAlt?MOD_ALT:0)|(g_newShift?MOD_SHIFT:0);
            e.vk=(UINT)g_newVK;
            e.label=g_newLabel; e.action=g_newAction; e.active=false;
            RegisterHotkey(e);
            g_hotkeys.push_back(e);
        }
        ImGui::Separator();

        if(ImGui::BeginTable("hkt",5,ImGuiTableFlags_RowBg|ImGuiTableFlags_BordersOuter|ImGuiTableFlags_BordersInnerV)){
            ImGui::TableSetupColumn("Label"); ImGui::TableSetupColumn("Combo"); ImGui::TableSetupColumn("Action"); ImGui::TableSetupColumn("State",ImGuiTableColumnFlags_WidthFixed,60); ImGui::TableSetupColumn("##del",ImGuiTableColumnFlags_WidthFixed,60);
            ImGui::TableHeadersRow();
            for(int i=0;i<(int)g_hotkeys.size();++i){
                auto& e=g_hotkeys[i];
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);ImGui::TextUnformatted(e.label.c_str());
                ImGui::TableSetColumnIndex(1);
                std::string combo;
                if(e.modifiers&MOD_CONTROL)combo+="Ctrl+";
                if(e.modifiers&MOD_ALT)combo+="Alt+";
                if(e.modifiers&MOD_SHIFT)combo+="Shift+";
                combo+=VKName(e.vk);
                ImGui::TextUnformatted(combo.c_str());
                ImGui::TableSetColumnIndex(2);ImGui::TextUnformatted(e.action.c_str());
                ImGui::TableSetColumnIndex(3);ImGui::TextColored(e.active?ImVec4(0.3f,1.f,0.3f,1.f):ImVec4(1.f,0.3f,0.3f,1.f),e.active?"ON":"OFF");
                ImGui::TableSetColumnIndex(4);
                ImGui::PushID(i);
                if(ImGui::SmallButton("Del")){if(e.active)UnregisterHotkey(e);g_hotkeys.erase(g_hotkeys.begin()+i);ImGui::PopID();break;}
                ImGui::PopID();
            }
            ImGui::EndTable();
        }
        ImGui::Separator();
        ImGui::TextColored(ImVec4(0.5f,0.5f,0.5f,1.f),"Log");
        ImGui::BeginChild("##log",ImVec2(0,120),true);
        for(auto& s:g_log)ImGui::TextUnformatted(s.c_str());
        ImGui::EndChild();
        ImGui::End();

        ImGui::Render();
        const float cc[4]={0.08f,0.08f,0.1f,1.f};
        g_pCtx->OMSetRenderTargets(1,&g_pRTV,nullptr);
        g_pCtx->ClearRenderTargetView(g_pRTV,cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_pChain->Present(1,0);
    }
    ImGui_ImplDX11_Shutdown();ImGui_ImplWin32_Shutdown();ImGui::DestroyContext();
    CleanupDX();DestroyWindow(g_hwnd);UnregisterClassW(wc.lpszClassName,wc.hInstance);
    return 0;
}
static bool CreateDX(HWND h){DXGI_SWAP_CHAIN_DESC sd={};sd.BufferCount=2;sd.BufferDesc.Format=DXGI_FORMAT_R8G8B8A8_UNORM;sd.BufferDesc.RefreshRate={60,1};sd.Flags=DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;sd.BufferUsage=DXGI_USAGE_RENDER_TARGET_OUTPUT;sd.OutputWindow=h;sd.SampleDesc={1,0};sd.Windowed=TRUE;sd.SwapEffect=DXGI_SWAP_EFFECT_DISCARD;const D3D_FEATURE_LEVEL fl[]={D3D_FEATURE_LEVEL_11_0,D3D_FEATURE_LEVEL_10_0};D3D_FEATURE_LEVEL fo;HRESULT hr=D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_HARDWARE,nullptr,0,fl,2,D3D11_SDK_VERSION,&sd,&g_pChain,&g_pDev,&fo,&g_pCtx);if(hr==DXGI_ERROR_UNSUPPORTED)hr=D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_WARP,nullptr,0,fl,2,D3D11_SDK_VERSION,&sd,&g_pChain,&g_pDev,&fo,&g_pCtx);if(hr!=S_OK)return false;CreateRTV();return true;}
static void CleanupDX(){CleanupRTV();if(g_pChain){g_pChain->Release();g_pChain=nullptr;}if(g_pCtx){g_pCtx->Release();g_pCtx=nullptr;}if(g_pDev){g_pDev->Release();g_pDev=nullptr;}}
static void CreateRTV(){ID3D11Texture2D*p=nullptr;g_pChain->GetBuffer(0,IID_PPV_ARGS(&p));if(p){g_pDev->CreateRenderTargetView(p,nullptr,&g_pRTV);p->Release();}}
static void CleanupRTV(){if(g_pRTV){g_pRTV->Release();g_pRTV=nullptr;}}
''',
        "headers": [],
        "subsystem": "Windows",
        "extraLib": "d3d11.lib;dxgi.lib;user32.lib;gdi32.lib;shell32.lib",
        "extraInc":  "imgui;imgui/backends",
        "setup_note": "ImGui setup required — same as Dear ImGui DX11 template.",
    },

    "blank": {
        "label": "Blank Project",
        "desc":  "Empty main.cpp with common includes — start from scratch.",
        "cpp": '''\
#include <iostream>
#include <string>
#include <vector>
#include <memory>

int main(int argc, char* argv[]) {
    // Your code here
    return 0;
}
''',
        "headers": [],
    },
}


# ─────────────────────────────────────────────
# C++ Creator: Code Generation & Build
# ─────────────────────────────────────────────

def get_cpp_templates():
    """Return template metadata (without the large cpp strings) for UI listing."""
    return [
        {"id": tid, "label": t["label"], "desc": t["desc"]}
        for tid, t in CPP_TEMPLATES.items()
    ]


def create_cpp_project(out_folder, project_name, template_id, custom_code="",
                       subsystem="Console", extra_lib="", extra_inc="",
                       cpp_std="/std:c++17", config="Release", runtime="/MT"):
    """
    Create a new C++ project from a template (or custom code) in `out_folder/project_name/`.
    Generates:
      - main.cpp  (or <project_name>.cpp)
      - <project_name>.vcxproj
    Returns {"ok": bool, "folder": str, "files": [...], "error": str}
    """
    import uuid as _uuid

    # Sanitize project name for filesystem
    safe_name = re.sub(r'[^\w\-]', '_', project_name.strip()) or "MyProject"

    project_dir = os.path.join(out_folder, safe_name)
    os.makedirs(project_dir, exist_ok=True)

    # ── Get source code ──────────────────────────────────────────────────────────
    setup_note = ""
    if custom_code.strip():
        code = custom_code
    elif template_id in CPP_TEMPLATES:
        code = CPP_TEMPLATES[template_id]["cpp"]
        tmpl = CPP_TEMPLATES[template_id]
        if not extra_lib and tmpl.get("extraLib"):
            extra_lib = tmpl["extraLib"]
        if not extra_inc and tmpl.get("extraInc"):
            extra_inc = tmpl["extraInc"]
        if tmpl.get("subsystem"):
            subsystem = tmpl["subsystem"]
        setup_note = tmpl.get("setup_note", "")
    else:
        code = CPP_TEMPLATES["blank"]["cpp"]

    # ── Write main.cpp ───────────────────────────────────────────────────────────
    cpp_filename = "main.cpp"
    cpp_path = os.path.join(project_dir, cpp_filename)
    with open(cpp_path, "w", encoding="utf-8") as f:
        f.write(code)

    # ── Generate .vcxproj ────────────────────────────────────────────────────────
    proj_guid = "{" + str(_uuid.uuid4()).upper() + "}"

    _std_map = {
        "/std:c++14": "stdcpp14", "/std:c++17": "stdcpp17",
        "/std:c++20": "stdcpp20", "/std:c++latest": "stdcpplatest",
    }
    std_val = _std_map.get(cpp_std, "stdcpp17")

    rt_map = {"/MT": "MultiThreaded", "/MD": "MultiThreadedDLL",
              "/MTd": "MultiThreadedDebug", "/MDd": "MultiThreadedDebugDLL"}
    rt_val = rt_map.get(runtime, "MultiThreaded")

    subsys_val = "Windows" if subsystem == "Windows" else "Console"

    inc_str = extra_inc.strip(";") + ";%(AdditionalIncludeDirectories)" if extra_inc.strip() else "%(AdditionalIncludeDirectories)"
    lib_str = extra_lib.strip(";") + ";%(AdditionalDependencies)" if extra_lib.strip() else "%(AdditionalDependencies)"
    use_debug = "true" if "Debug" in config else "false"

    vcxproj = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by Build Doctor C++ Creator -->
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">

  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="{config}|x64">
      <Configuration>{config}</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
  </ItemGroup>

  <PropertyGroup Label="Globals">
    <ProjectGuid>{proj_guid}</ProjectGuid>
    <RootNamespace>{safe_name}</RootNamespace>
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>

  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />

  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='{config}|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>{use_debug}</UseDebugLibraries>
    <PlatformToolset>v143</PlatformToolset>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>

  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />

  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='{config}|x64'">
    <OutDir>$(ProjectDir){config}\\</OutDir>
    <IntDir>$(ProjectDir){config}\\int\\</IntDir>
    <TargetName>{safe_name}</TargetName>
  </PropertyGroup>

  <ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='{config}|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <Optimization>MaxSpeed</Optimization>
      <PreprocessorDefinitions>NDEBUG;_CONSOLE;%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <LanguageStandard>{std_val}</LanguageStandard>
      <RuntimeLibrary>{rt_val}</RuntimeLibrary>
      <ExceptionHandling>Sync</ExceptionHandling>
      <AdditionalIncludeDirectories>{inc_str}</AdditionalIncludeDirectories>
      <SDLCheck>false</SDLCheck>
      <ConformanceMode>true</ConformanceMode>
    </ClCompile>
    <Link>
      <SubSystem>{subsys_val}</SubSystem>
      <GenerateDebugInformation>{use_debug}</GenerateDebugInformation>
      <AdditionalDependencies>{lib_str}</AdditionalDependencies>
      <EnableCOMDATFolding>true</EnableCOMDATFolding>
      <OptimizeReferences>true</OptimizeReferences>
    </Link>
  </ItemDefinitionGroup>

  <ItemGroup>
    <ClCompile Include="{cpp_filename}" />
  </ItemGroup>

  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />

</Project>
"""

    vcxproj_path = os.path.join(project_dir, f"{safe_name}.vcxproj")
    with open(vcxproj_path, "w", encoding="utf-8") as f:
        f.write(vcxproj)

    return {
        "ok": True,
        "folder": project_dir,
        "name": safe_name,
        "files": [cpp_filename, f"{safe_name}.vcxproj"],
        "error": "",
        "setup_note": setup_note,
    }


def build_cpp_project(project_folder, config="Release", on_line=None):
    """
    Build a C++ project folder. Uses generate_build_bat + subprocess stream.
    Calls on_line(text, cls) for each output line.
    Returns {"ok": bool, "exe_path": str, "output": str, "returncode": int}
    """
    cfg = {
        "config": config,
        "std": "/std:c++17",
        "runtime": "/MT",
        "opt": "/O2",
        "parallel": True,
        "extraInc": "",
        "extraLib": "",
    }

    try:
        bat_path, _ = generate_build_bat(project_folder, cfg)
    except Exception as exc:
        msg = f"[!] Failed to generate build script: {exc}"
        if on_line:
            on_line(msg, "error")
        return {"ok": False, "exe_path": "", "output": msg, "returncode": -1}

    captured = ""
    proc = subprocess.Popen(
        ["cmd.exe", "/c", bat_path],
        cwd=project_folder,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="ignore",
    )

    for raw in proc.stdout:
        line = raw.rstrip()
        captured += line + "\n"
        lo = line.lower()
        if any(x in lo for x in ["error", "fatal", "failed"]):
            cls = "error"
        elif "warning" in lo:
            cls = "warn"
        elif any(x in lo for x in ["succeeded", "->", "build complete"]):
            cls = "info"
        else:
            cls = "default"
        if on_line:
            on_line(line, cls)

    proc.wait()
    success = proc.returncode == 0

    # ── Find produced EXE ──────────────────────────────────────────────────────
    exe_path = ""
    proj_name = os.path.basename(project_folder.rstrip("\\/"))
    candidates = [
        os.path.join(project_folder, config, f"{proj_name}.exe"),
        os.path.join(project_folder, "x64", config, f"{proj_name}.exe"),
        os.path.join(project_folder, f"{proj_name}.exe"),
    ]
    arrow_m = re.search(r"->\s+(.+\.exe)", captured, re.IGNORECASE)
    if arrow_m:
        ap = arrow_m.group(1).strip()
        if not os.path.isabs(ap):
            ap = os.path.join(project_folder, ap)
        candidates.insert(0, ap)
    for c in candidates:
        if os.path.isfile(c):
            exe_path = c
            break

    return {
        "ok": success,
        "exe_path": exe_path,
        "output": captured,
        "returncode": proc.returncode,
    }


def save_and_build_custom_cpp(out_folder, project_name, code, config="Release",
                              extra_lib="", extra_inc="", cpp_std="/std:c++17",
                              runtime="/MT", subsystem="Console",
                              on_line=None):
    """
    Convenience: create project from custom code + immediately build.
    Returns {"ok", "exe_path", "folder", "build_output", "errors"}
    """
    create_result = create_cpp_project(
        out_folder, project_name, "blank",
        custom_code=code,
        subsystem=subsystem,
        extra_lib=extra_lib,
        extra_inc=extra_inc,
        cpp_std=cpp_std,
        config=config,
        runtime=runtime,
    )

    if not create_result["ok"]:
        return {"ok": False, "exe_path": "", "folder": "", "build_output": "", "errors": create_result.get("error", "Unknown")}

    build_result = build_cpp_project(create_result["folder"], config=config, on_line=on_line)

    return {
        "ok":           build_result["ok"],
        "exe_path":     build_result["exe_path"],
        "folder":       create_result["folder"],
        "build_output": build_result["output"],
        "errors":       "" if build_result["ok"] else "Build failed — see output above.",
    }


# ─────────────────────────────────────────────
# Enhanced auto_fix_from_output with more rules
# ─────────────────────────────────────────────

_AUTO_FIX_RULES_ENHANCED = [
    # Ordering: MSB3202 FIRST (missing project files block everything)
    (r"error MSB3202",                 "fix_msb3202",        True,  "FIX MSB3202"),
    # vcpkg deps (ZSTD, OpenSSL, TBB, curl) before generic include pass
    (r"warning C4101|ZSTD_decompress|error C3861.*zstd"
     r"|error C1083[^']*(?:zstd|openssl)|OPENSSL_|openssl/"
     r"|oneapi/tbb/|tbb/parallel_invoke|error C1083[^']*(?:oneapi/tbb|tbb/parallel)"
     r"|curl/curl\.h|nlohmann/json\.hpp",
                                       "fix_vcpkg_deps",     True,  "FIX DEPS (vcpkg)"),
    # Missing includes
    (r"error C1083",                   "fix_cpp_includes",   True,  "FIX INCS"),
    # Precompiled header
    (r"error C1010",                   "fix_pch",            True,  "FIX PCH"),
    # DWORD→SIZE_T for WPM/RPM
    (r"error C2664.*(?:WriteProcessMemory|ReadProcessMemory)|"
     r"(?:WriteProcessMemory|ReadProcessMemory).*DWORD.*SIZE_T",
                                       "fix_winapi_size_t",  True,  "FIX SIZET"),
    # Linker errors
    (r"LNK2001|LNK2019|LNK1181|LNK1104|LNK1120",
                                       "fix_missing_libs",   True,  "FIX LIBS"),
    # vcxproj missing ClCompile entries (any unresolved that could be orphaned)
    (r"LNK2001|LNK2019|error C3861|error C2065",
                                       "fix_vcxproj_items",  False, "FIX VCXPROJ ITEMS"),
    # C# files
    (r"error CS2001|error CS0246",     "fix_cs_files",       False, "FIX CS FILES"),
    # NuGet restore
    (r"error CS0006|NU1101|NU1102|NU1103|packages\.config.*not found",
                                       "fix_dotnet_restore", False, "NUGET RESTORE"),
    # Luau
    (r"C4003.*LUAU_FASTFLAGVARIABLE|C2051.*BytecodeUtils|LuauBytecodeType.*undeclared"
     r"|error C1083[^']*'[^']*(?:Luau/|luau/|lua\.h|luaconf\.h|lualib\.h)",
                                       "fix_luau",           True,  "FIX LUAU"),
]

_FIX_FUNC_MAP_ENHANCED = {
    "fix_msb3202":        lambda folder, out: fix_msb3202(folder, out),
    "fix_vcpkg_deps":     lambda folder, out: fix_vcpkg_deps(folder, out),
    "fix_cpp_includes":   lambda folder, out: fix_cpp_missing_includes(folder, out),
    "fix_pch":            lambda folder, out: fix_pch(folder, out),
    "fix_winapi_size_t":  lambda folder, out: fix_winapi_size_t(folder, out),
    "fix_missing_libs":   lambda folder, out: fix_missing_libs(folder, out),
    "fix_vcxproj_items":  lambda folder, out: fix_vcxproj_missing_items(folder),
    "fix_cs_files":       lambda folder, out: fix_missing_cs_files(folder),
    "fix_dotnet_restore": lambda folder, out: _run_dotnet_restore_cmd(folder).get("output", "").splitlines(),
    "fix_luau":           lambda folder, out: fix_luau_submodule(folder, last_build_output=out),
}


def auto_fix_from_output_v2(folder, build_output, emit_line=None):
    """
    Enhanced auto-fix: more rules, dedup, streams progress.
    Returns (actions_list, fix_labels_applied).
    """
    actions_all    = []
    labels_applied = []
    applied_funcs  = set()   # prevent double-applying same fix

    def log(text, cls="dim"):
        actions_all.append(text)
        if emit_line:
            emit_line(text, cls)

    for pattern, func_name, needs_output, label in _AUTO_FIX_RULES_ENHANCED:
        if func_name in applied_funcs:
            continue
        if re.search(pattern, build_output, re.IGNORECASE):
            log(f"[AUTO-FIX] Detected → {label}", "warn")
            try:
                out_arg      = build_output if needs_output else ""
                fix_results  = _FIX_FUNC_MAP_ENHANCED[func_name](folder, out_arg)
                for line in (fix_results or []):
                    cls = ("info"  if line.startswith("[FIXED") else
                           "error" if line.startswith("[ERROR") else
                           "warn"  if line.startswith("[WARN")  else "dim")
                    log(line, cls)
                labels_applied.append(label)
                applied_funcs.add(func_name)
            except Exception as exc:
                log(f"[ERROR] {label} threw: {exc}", "error")

    if not labels_applied:
        log("[AUTO-FIX] No auto-applicable fixes matched this build output.", "dim")

    return actions_all, labels_applied


# ─────────────────────────────────────────────
# Diagnosis
# ─────────────────────────────────────────────

def diagnose(text):
    fixes = []
    for pattern, msg in PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            if msg not in fixes:
                fixes.append(msg)
    if not fixes:
        fixes.append("No known issue detected — inspect compiler output above manually.")
    return fixes


# ─────────────────────────────────────────────
# JavaScript API (called from the UI)
# ─────────────────────────────────────────────

class Api:
    def __init__(self):
        self._window      = None
        self._last_output = ""   # stored after every build for C1083 auto-fix

    def set_window(self, window):
        self._window = window

    # ── scan ─────────────────────────────────────────────────────────────────
    def scan(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            scan    = scan_project(folder)
            vcvars  = find_vcvars64()
            fw_info = check_framework_consistency(folder)

            if scan["sln"]:
                strategy = "MSBuild (solution)"
            elif scan["vcxproj"]:
                strategy = "MSBuild (vcxproj)"
            elif scan["csproj"]:
                strategy = "MSBuild (C# csproj)"
            elif scan["cpp"] or scan["c"]:
                strategy = "MSVC cl.exe (source files)"
            elif scan["cmake"]:
                strategy = "CMake"
            else:
                strategy = "Unknown — no buildable files found"

            return json.dumps({
                "ok": True,
                "files": scan,
                "strategy": strategy,
                "vcvars": vcvars or "NOT FOUND",
                "frameworks": fw_info
            })
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_cs_files (passes 1 & 2 only) ────────────────────────────────────
    def fix_cs_files(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_missing_cs_files(folder)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_duplicate_refs (pass 3) ──────────────────────────────────────────
    def fix_duplicate_refs(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_duplicate_refs(folder)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_cpp_headers (pass 5) ─────────────────────────────────────────────
    def fix_cpp_headers(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_cpp_headers(folder)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_vcxproj_items (pass 9 — missing ClCompile / ClInclude) ──────────
    def fix_vcxproj_items(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_vcxproj_missing_items(folder)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_cpp_includes (pass 6 — C1083 missing include dirs) ──────────────
    def fix_cpp_includes(self, folder, build_output=""):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            output  = build_output if build_output else self._last_output
            actions = fix_cpp_missing_includes(folder, output)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_luau (pass 7 — Luau submodule + include injection) ───────────────
    def fix_luau(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_luau_submodule(
                folder,
                last_build_output=self._last_output,
                emit_line=lambda text, cls: self._emit("log", {"text": text, "cls": cls}),
            )
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_missing_libs (pass 10 — LNK lib finder) ─────────────────────────
    def fix_missing_libs(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_missing_libs(folder, self._last_output)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_pch (pass 11 — PCH auto-stub / disable) ──────────────────────────
    def fix_pch(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_pch(folder, self._last_output)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_winapi_size_t (pass 11b — DWORD→SIZE_T for WPM/RPM) ─────────────
    def fix_winapi_size_t(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_winapi_size_t(folder, self._last_output)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_vcpkg_deps (pass 12 — ZSTD / OpenSSL / C4101) ───────────────────
    def fix_vcpkg_deps(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_vcpkg_deps(folder, self._last_output)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── fix_msb3202 (pass 13 — missing .vcxproj/.csproj in .sln) ────────────
    def fix_msb3202(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_msb3202(folder, self._last_output)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── auto_fix_loop ─────────────────────────────────────────────────────────
    def auto_fix_loop(self, folder, config_json, max_retries=3):
        """
        Run build → if failed, auto-detect and apply fixes → retry.
        Streams live via JS events. max_retries caps the loop.
        """
        def _run():
            config = json.loads(config_json)

            for attempt in range(1, max_retries + 2):
                self._emit("log", {"text": f"", "cls": "dim"})
                self._emit("log", {
                    "text": f"═══ AUTO-FIX LOOP — Attempt {attempt}/{max_retries + 1} ═══",
                    "cls": "heading"
                })

                # ── Build ──────────────────────────────────────────────────────
                try:
                    bat_path, _ = generate_build_bat(folder, config)
                    self._emit("log", {"text": "[+] build.bat generated.", "cls": "info"})
                except Exception as exc:
                    self._emit("log", {"text": f"[!] {exc}", "cls": "error"})
                    self._emit("autofix_done", {"success": False, "attempts": attempt,
                                                "diag": [str(exc)], "exePath": ""})
                    return

                captured = ""
                proc = subprocess.Popen(
                    ["cmd.exe", "/c", bat_path],
                    cwd=folder,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    encoding="utf-8",
                    errors="ignore",
                )
                for line in proc.stdout:
                    stripped  = line.rstrip()
                    captured += stripped + "\n"
                    lo = stripped.lower()
                    if any(x in lo for x in ["error", "fatal", "failed"]):
                        cls = "error"
                    elif "warning" in lo:
                        cls = "warn"
                    elif any(x in lo for x in ["succeeded", "->", "build complete"]):
                        cls = "info"
                    else:
                        cls = "default"
                    self._emit("log", {"text": stripped, "cls": cls})

                proc.wait()
                self._last_output = captured
                success = proc.returncode == 0

                if success:
                    # ── Find EXE ──────────────────────────────────────────────
                    exe_path = ""
                    conf      = config.get("config", "Release")
                    proj_name = os.path.basename(folder.rstrip("\\/")) or "project"
                    candidates = [
                        os.path.join(folder, "x64", conf, f"{proj_name}.exe"),
                        os.path.join(folder, conf, f"{proj_name}.exe"),
                        os.path.join(folder, f"{proj_name}.exe"),
                    ]
                    arrow_m = re.search(r"->\s+(.+\.exe)", captured, re.IGNORECASE)
                    if arrow_m:
                        ap = arrow_m.group(1).strip()
                        if not os.path.isabs(ap):
                            ap = os.path.join(folder, ap)
                        candidates.insert(0, ap)
                    for c in candidates:
                        if os.path.isfile(c):
                            exe_path = c
                            break

                    # ── SHA256 fingerprint ────────────────────────────────────
                    if exe_path:
                        h = sha256_file(exe_path)
                        if h:
                            self._emit("log", {
                                "text": f"[SHA256] {os.path.basename(exe_path)} → {h}",
                                "cls": "dim"
                            })

                    self._emit("autofix_done", {
                        "success":  True,
                        "attempts": attempt,
                        "diag":     diagnose(captured),
                        "exePath":  exe_path,
                        "sha256":   sha256_file(exe_path) if exe_path else "",
                    })
                    return

                # ── Build failed — attempt auto-fix before retrying ────────────
                if attempt <= max_retries:
                    self._emit("log", {"text": "", "cls": "dim"})
                    self._emit("log", {
                        "text": f"[AUTO-FIX] Build failed — analyzing errors and applying fixes...",
                        "cls": "warn"
                    })
                    fix_actions, labels = auto_fix_from_output(
                        folder, captured,
                        emit_line=lambda t, c: self._emit("log", {"text": t, "cls": c})
                    )
                    if not labels:
                        self._emit("log", {
                            "text": "[AUTO-FIX] No applicable auto-fix found — stopping loop.",
                            "cls": "error"
                        })
                        break
                    self._emit("log", {
                        "text": f"[AUTO-FIX] Applied: {', '.join(labels)} — retrying build...",
                        "cls": "info"
                    })
                else:
                    break

            # Loop exhausted without success
            self._emit("autofix_done", {
                "success":  False,
                "attempts": min(attempt, max_retries + 1),
                "diag":     diagnose(self._last_output),
                "exePath":  "",
                "sha256":   "",
            })

        threading.Thread(target=_run, daemon=True).start()
        return json.dumps({"ok": True})


    def run_dotnet_restore(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "output": "Folder not found", "returncode": -1})
        try:
            r = _run_dotnet_restore_cmd(folder)
            return json.dumps({"ok": r["ok"], "output": r["output"], "returncode": r["returncode"]})
        except Exception as exc:
            return json.dumps({"ok": False, "output": str(exc), "returncode": -1})

    # ── fix_all (all passes) ─────────────────────────────────────────────────
    def fix_all(self, folder):
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            actions = fix_all_cs(folder)
            return json.dumps({"ok": True, "actions": actions})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── generate ─────────────────────────────────────────────────────────────
    def generate(self, folder, config_json):
        config = json.loads(config_json)
        if not os.path.isdir(folder):
            return json.dumps({"ok": False, "error": "Folder not found"})
        try:
            bat_path, _ = generate_build_bat(folder, config)
            with open(bat_path, encoding="utf-8") as f:
                preview = f.read()
            return json.dumps({"ok": True, "path": bat_path, "preview": preview})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── run_build ─────────────────────────────────────────────────────────────
    def run_build(self, folder, config_json):
        def _run():
            config = json.loads(config_json)

            # Always regenerate build.bat (creates .vcxproj if needed)
            try:
                bat_path, scan_result = generate_build_bat(folder, config)
                self._emit("log", {"text": "[+] build.bat generated.", "cls": "info"})
            except Exception as exc:
                self._emit("log", {"text": f"[!] {exc}", "cls": "error"})
                self._emit("done", {"success": False, "diag": [str(exc)], "exePath": ""})
                return

            captured = ""

            proc = subprocess.Popen(
                ["cmd.exe", "/c", bat_path],
                cwd=folder,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="ignore",
            )

            for line in proc.stdout:
                stripped  = line.rstrip()
                captured += stripped + "\n"

                lo = stripped.lower()
                if any(x in lo for x in ["error", "fatal", "failed"]):
                    cls = "error"
                elif any(x in lo for x in ["warning"]):
                    cls = "warn"
                elif any(x in lo for x in ["succeeded", "->", "build complete"]):
                    cls = "info"
                else:
                    cls = "default"

                self._emit("log", {"text": stripped, "cls": cls})

            proc.wait()
            success = proc.returncode == 0
            fixes   = diagnose(captured)
            self._last_output = captured   # ← store for C1083 fix pass

            # ── Locate the produced .exe ──────────────────────────────────
            exe_path = ""
            if success:
                conf      = config.get("config", "Release")
                proj_name = os.path.basename(folder.rstrip("\\/")) or "project"
                candidates = [
                    os.path.join(folder, "x64", conf, f"{proj_name}.exe"),
                    os.path.join(folder, conf, f"{proj_name}.exe"),
                    os.path.join(folder, "x64", conf, "app.exe"),
                    os.path.join(folder, conf, "app.exe"),
                    os.path.join(folder, f"{proj_name}.exe"),
                    os.path.join(folder, "app.exe"),
                ]
                # Parse MSBuild "-> path\app.exe" lines for the exact output path
                arrow_m = re.search(r"->\s+(.+\.exe)", captured, re.IGNORECASE)
                if arrow_m:
                    arrow_path = arrow_m.group(1).strip()
                    abs_arrow  = arrow_path if os.path.isabs(arrow_path) else os.path.join(folder, arrow_path)
                    candidates.insert(0, abs_arrow)

                for c in candidates:
                    if os.path.isfile(c):
                        exe_path = c
                        break

                if exe_path:
                    self._emit("log", {"text": f"[OK] Output EXE: {exe_path}", "cls": "info"})
                    h = sha256_file(exe_path)
                    if h:
                        self._emit("log", {
                            "text": f"[SHA256] {os.path.basename(exe_path)} → {h}",
                            "cls": "dim"
                        })
                else:
                    self._emit("log", {"text": "[?] Build succeeded but .exe location unknown.", "cls": "warn"})

            _has_luau = bool(re.search(
                r"error C1083[^']*'[^']*(?:Luau/|luau/|xxhash\.h"
                r"|lua\.h|luaconf\.h|lualib\.h|luacode\.h|luacodegen\.h"
                r"|lapi\.h|ldo\.h|lgc\.h|lobject\.h|lstate\.h|lstring\.h"
                r"|ltable\.h|lmem\.h|ldebug\.h|lfunc\.h|lvm\.h"
                r"|compiler\.cpp|lexer\.cpp|parser\.cpp|location\.cpp"
                r"|confusables\.cpp|constantfolding\.cpp|costmodel\.cpp"
                r"|lcode\.cpp|stringutils\.cpp|tableshape\.cpp|timetrace\.cpp"
                r"|types\.cpp|valuetracking\.cpp|bytecodebuilder\.cpp|bytecodeutils\.cpp"
                r"|lapi\.cpp|ldo\.cpp|lgc\.cpp|lobject\.cpp|lstate\.cpp"
                r"|lstring\.cpp|lvmexecute\.cpp|lvmload\.cpp|lvmutils\.cpp)",
                captured, re.IGNORECASE
            )) or bool(re.search(
                # Version-mismatch errors — header/source from different Luau commits
                r"C4003.*LUAU_FASTFLAGVARIABLE"          # macro arg count changed
                r"|C2051.*BytecodeUtils"                  # enum not constant (tag type changed)
                r"|C2065.*hasConstants"                   # member renamed between versions
                r"|C2327.*BytecodeBuilder.*constants"     # member not a type (renamed)
                r"|LuauBytecodeType.*undeclared"          # type moved/renamed
                r"|C2039.*Type_Vector.*BytecodeBuilder",  # struct member gone in newer ver
                captured, re.IGNORECASE
            ))
            self._emit("done", {
                "success":    success,
                "returncode": proc.returncode,
                "diag":       fixes,
                "exePath":    exe_path,
                "sha256":     sha256_file(exe_path) if exe_path else "",
                "hasC1083":   bool(re.search(r"error C1083", captured, re.IGNORECASE)),
                "hasLuau":    _has_luau,
                "hasLnk":     bool(re.search(r"LNK2001|LNK2019|LNK1181|LNK1104|LNK1120", captured, re.IGNORECASE)),
                "hasPch":     bool(re.search(r"error C1010", captured, re.IGNORECASE)),
                "hasWinapiSize": bool(re.search(
                    r"error C2664.*(?:WriteProcessMemory|ReadProcessMemory)"
                    r"|(?:WriteProcessMemory|ReadProcessMemory).*DWORD.*SIZE_T",
                    captured, re.IGNORECASE)),
            })

        threading.Thread(target=_run, daemon=True).start()
        return json.dumps({"ok": True})


    # ── auto_fix_loop_v2 ─────────────────────────────────────────────────────
    def auto_fix_loop_v2(self, folder, config_json, max_retries=3):
        """
        Enhanced auto-fix loop using auto_fix_from_output_v2 (dedup, more rules).
        Streams live via JS events.
        """
        def _run():
            config = json.loads(config_json)

            for attempt in range(1, max_retries + 2):
                self._emit("log", {"text": "", "cls": "dim"})
                self._emit("log", {
                    "text": f"═══ AUTO-FIX LOOP v2 — Attempt {attempt}/{max_retries + 1} ═══",
                    "cls": "heading"
                })

                try:
                    bat_path, _ = generate_build_bat(folder, config)
                    self._emit("log", {"text": "[+] build.bat generated.", "cls": "info"})
                except Exception as exc:
                    self._emit("log", {"text": f"[!] {exc}", "cls": "error"})
                    self._emit("cr_build_done", {"ok": False, "folder": folder, "exe_path": ""})
                    return

                captured = ""
                proc = subprocess.Popen(
                    ["cmd.exe", "/c", bat_path],
                    cwd=folder,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True, encoding="utf-8", errors="ignore",
                )
                for line in proc.stdout:
                    stripped  = line.rstrip()
                    captured += stripped + "\n"
                    lo = stripped.lower()
                    if any(x in lo for x in ["error", "fatal", "failed"]):
                        cls = "error"
                    elif "warning" in lo:
                        cls = "warn"
                    elif any(x in lo for x in ["succeeded", "->", "build complete"]):
                        cls = "info"
                    else:
                        cls = "default"
                    self._emit("log", {"text": stripped, "cls": cls})

                proc.wait()
                self._last_output = captured
                success = proc.returncode == 0

                if success:
                    exe_path  = ""
                    conf      = config.get("config", "Release")
                    proj_name = os.path.basename(folder.rstrip("\\/")) or "project"
                    candidates = [
                        os.path.join(folder, conf, f"{proj_name}.exe"),
                        os.path.join(folder, "x64", conf, f"{proj_name}.exe"),
                        os.path.join(folder, f"{proj_name}.exe"),
                    ]
                    arrow_m = re.search(r"->\s+(.+\.exe)", captured, re.IGNORECASE)
                    if arrow_m:
                        ap = arrow_m.group(1).strip()
                        if not os.path.isabs(ap):
                            ap = os.path.join(folder, ap)
                        candidates.insert(0, ap)
                    for c in candidates:
                        if os.path.isfile(c):
                            exe_path = c
                            break
                    if exe_path:
                        h = sha256_file(exe_path)
                        if h:
                            self._emit("log", {"text": f"[SHA256] {os.path.basename(exe_path)} → {h}", "cls": "dim"})
                    self._emit("cr_build_done", {"ok": True, "folder": folder, "exe_path": exe_path})
                    return

                if attempt <= max_retries:
                    self._emit("log", {"text": "[AUTO-FIX v2] Applying enhanced fixes...", "cls": "warn"})
                    _, labels = auto_fix_from_output_v2(
                        folder, captured,
                        emit_line=lambda t, c: self._emit("log", {"text": t, "cls": c})
                    )
                    if not labels:
                        self._emit("log", {"text": "[AUTO-FIX v2] No applicable fix found — stopping.", "cls": "error"})
                        break
                    self._emit("log", {"text": f"[AUTO-FIX v2] Applied: {', '.join(labels)} — retrying...", "cls": "info"})
                else:
                    break

            self._emit("cr_build_done", {"ok": False, "folder": folder, "exe_path": ""})

        threading.Thread(target=_run, daemon=True).start()
        return json.dumps({"ok": True})

    # ── get_templates ─────────────────────────────────────────────────────────
    def get_templates(self):
        try:
            return json.dumps({"ok": True, "templates": get_cpp_templates()})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── create_project ────────────────────────────────────────────────────────
    def create_project(self, out_folder, name, template_id, std, config, runtime,
                        subsystem, extra_lib, extra_inc):
        try:
            r = create_cpp_project(
                out_folder, name, template_id,
                subsystem=subsystem, extra_lib=extra_lib, extra_inc=extra_inc,
                cpp_std=std, config=config, runtime=runtime,
            )
            return json.dumps(r)
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── create_and_build ──────────────────────────────────────────────────────
    def create_and_build(self, out_folder, name, template_id, custom_code,
                          std, config, runtime, subsystem, extra_lib, extra_inc):
        def _run():
            try:
                create_r = create_cpp_project(
                    out_folder, name, template_id,
                    custom_code=custom_code,
                    subsystem=subsystem, extra_lib=extra_lib, extra_inc=extra_inc,
                    cpp_std=std, config=config, runtime=runtime,
                )
                if not create_r["ok"]:
                    self._emit("log", {"text": f"[!] Create failed: {create_r.get('error')}", "cls": "error"})
                    self._emit("cr_build_done", {"ok": False, "folder": "", "exe_path": ""})
                    return
                folder = create_r["folder"]
                for f in create_r["files"]:
                    self._emit("log", {"text": f"[+] Created: {f}", "cls": "info"})
                if create_r.get("setup_note"):
                    self._emit("log", {"text": "", "cls": "dim"})
                    self._emit("log", {"text": "[!] SETUP REQUIRED:", "cls": "warn"})
                    for line in create_r["setup_note"].splitlines():
                        self._emit("log", {"text": "    " + line, "cls": "warn"})
                    self._emit("log", {"text": "", "cls": "dim"})
                self._emit("log", {"text": f"[*] Building: {folder}", "cls": "info"})
            except Exception as exc:
                self._emit("log", {"text": f"[!] {exc}", "cls": "error"})
                self._emit("cr_build_done", {"ok": False, "folder": "", "exe_path": ""})
                return

            cfg = {"config": config, "std": std, "runtime": runtime,
                   "opt": "/O2", "parallel": True,
                   "extraInc": extra_inc, "extraLib": extra_lib}
            self._emit("log", {"text": "", "cls": "dim"})
            # delegate to v2 loop (1 attempt + up to 3 fix retries)
            # call directly in this thread
            for attempt in range(1, 5):
                self._emit("log", {"text": f"--- Build attempt {attempt} ---", "cls": "dim"})
                try:
                    bat_path, _ = generate_build_bat(folder, cfg)
                except Exception as exc:
                    self._emit("log", {"text": f"[!] {exc}", "cls": "error"})
                    self._emit("cr_build_done", {"ok": False, "folder": folder, "exe_path": ""})
                    return

                captured = ""
                proc = subprocess.Popen(
                    ["cmd.exe", "/c", bat_path],
                    cwd=folder,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, encoding="utf-8", errors="ignore",
                )
                for line in proc.stdout:
                    s = line.rstrip()
                    captured += s + "\n"
                    lo = s.lower()
                    if any(x in lo for x in ["error", "fatal", "failed"]):
                        cls = "error"
                    elif "warning" in lo:
                        cls = "warn"
                    elif any(x in lo for x in ["succeeded", "->", "build complete"]):
                        cls = "info"
                    else:
                        cls = "default"
                    self._emit("log", {"text": s, "cls": cls})
                proc.wait()
                self._last_output = captured

                if proc.returncode == 0:
                    exe_path  = ""
                    proj_name = os.path.basename(folder.rstrip("\\/")) or name
                    candidates = [
                        os.path.join(folder, config, f"{proj_name}.exe"),
                        os.path.join(folder, "x64", config, f"{proj_name}.exe"),
                        os.path.join(folder, f"{proj_name}.exe"),
                    ]
                    am = re.search(r"->\s+(.+\.exe)", captured, re.IGNORECASE)
                    if am:
                        ap = am.group(1).strip()
                        if not os.path.isabs(ap):
                            ap = os.path.join(folder, ap)
                        candidates.insert(0, ap)
                    for c in candidates:
                        if os.path.isfile(c):
                            exe_path = c
                            break
                    if exe_path:
                        h = sha256_file(exe_path)
                        if h:
                            self._emit("log", {"text": f"[SHA256] {os.path.basename(exe_path)} → {h}", "cls": "dim"})
                    self._emit("cr_build_done", {"ok": True, "folder": folder, "exe_path": exe_path})
                    return

                if attempt < 4:
                    self._emit("log", {"text": "[AUTO-FIX v2] Analyzing errors...", "cls": "warn"})
                    _, labels = auto_fix_from_output_v2(
                        folder, captured,
                        emit_line=lambda t, c: self._emit("log", {"text": t, "cls": c})
                    )
                    if not labels:
                        self._emit("log", {"text": "[AUTO-FIX v2] No fix matched — giving up.", "cls": "error"})
                        break
                    self._emit("log", {"text": f"[AUTO-FIX v2] Applied: {', '.join(labels)}", "cls": "info"})

            self._emit("cr_build_done", {"ok": False, "folder": folder, "exe_path": ""})

        threading.Thread(target=_run, daemon=True).start()
        return json.dumps({"ok": True})

    # ── read_cpp ──────────────────────────────────────────────────────────────
    def read_cpp(self, folder):
        """Read the first .cpp file in a project folder."""
        try:
            for f in os.listdir(folder):
                if f.lower().endswith(".cpp"):
                    path = os.path.join(folder, f)
                    with open(path, encoding="utf-8", errors="ignore") as fh:
                        code = fh.read()
                    return json.dumps({"ok": True, "code": code, "path": path})
            return json.dumps({"ok": False, "error": "No .cpp file found"})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── write_cpp ─────────────────────────────────────────────────────────────
    def write_cpp(self, path, code):
        """Write code back to a .cpp file."""
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write(code)
            return json.dumps({"ok": True})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── open_folder ───────────────────────────────────────────────────────────
    def open_folder(self, folder):
        """Open folder in Windows Explorer."""
        try:
            subprocess.Popen(["explorer", os.path.normpath(folder)])
            return json.dumps({"ok": True})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})

    # ── run_exe ───────────────────────────────────────────────────────────────
    def run_exe(self, exe_path):
        """Launch the compiled .exe."""
        try:
            subprocess.Popen([exe_path], cwd=os.path.dirname(exe_path))
            return json.dumps({"ok": True})
        except Exception as exc:
            return json.dumps({"ok": False, "error": str(exc)})


    # ── ZukaTech Lua Obfuscator ───────────────────────────────────────────────
    def obfuscate_lua(self, input_path, output_path, lua_exe, main_lua):
        """
        Run ZukaTech obfuscator: lua main.lua <input> <output>
        Streams live output via JS events (obf_log / obf_done).
        """
        def _run():
            self._emit("obf_log", {"text": "─── ZukaTech Obfuscator Starting ───", "cls": "heading"})

            # Validate paths
            for label, p in [("Input file", input_path), ("main.lua", main_lua)]:
                if not os.path.isfile(p):
                    self._emit("obf_log", {"text": f"[!] {label} not found: {p}", "cls": "error"})
                    self._emit("obf_done", {"ok": False, "output": ""})
                    return

            if not lua_exe.strip():
                self._emit("obf_log", {"text": "[!] Lua executable path is empty.", "cls": "error"})
                self._emit("obf_done", {"ok": False, "output": ""})
                return

            # Make sure output dir exists
            out_dir = os.path.dirname(output_path)
            if out_dir:
                os.makedirs(out_dir, exist_ok=True)

            cmd = [lua_exe, main_lua, input_path, output_path]
            self._emit("obf_log", {"text": f"[>] {' '.join(cmd)}", "cls": "dim"})
            self._emit("obf_log", {"text": "", "cls": "dim"})

            try:
                proc = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    encoding="utf-8",
                    errors="ignore",
                )
                captured = ""
                for line in proc.stdout:
                    stripped  = line.rstrip()
                    captured += stripped + "\n"
                    lo = stripped.lower()
                    if any(x in lo for x in ["error", "fail", "panic"]):
                        cls = "error"
                    elif any(x in lo for x in ["warn", "skip"]):
                        cls = "warn"
                    elif any(x in lo for x in ["zukatech", "done", "detected", "✓"]):
                        cls = "info"
                    else:
                        cls = "default"
                    self._emit("obf_log", {"text": stripped, "cls": cls})
                proc.wait()

                if proc.returncode == 0 and os.path.isfile(output_path):
                    kb = os.path.getsize(output_path) / 1024
                    self._emit("obf_log", {"text": "", "cls": "dim"})
                    self._emit("obf_log", {"text": f"✓ Done!  {kb:.1f} KB  →  {output_path}", "cls": "info"})
                    self._emit("obf_done", {"ok": True, "output": output_path, "kb": round(kb, 1)})
                else:
                    self._emit("obf_log", {"text": f"[!] Obfuscation failed (exit {proc.returncode}).", "cls": "error"})
                    self._emit("obf_done", {"ok": False, "output": ""})
            except FileNotFoundError:
                self._emit("obf_log", {"text": f"[!] Lua executable not found: {lua_exe}", "cls": "error"})
                self._emit("obf_log", {"text": "    Install Lua 5.1 / LuaJIT and ensure it's on PATH.", "cls": "dim"})
                self._emit("obf_done", {"ok": False, "output": ""})
            except Exception as exc:
                self._emit("obf_log", {"text": f"[!] {exc}", "cls": "error"})
                self._emit("obf_done", {"ok": False, "output": ""})

        threading.Thread(target=_run, daemon=True).start()

    def obf_browse_file(self, title, exts):
        """Open a file-picker dialog. exts e.g. 'Lua files (*.lua)|*.lua'"""
        result = self._window.create_file_dialog(
            webview.OPEN_DIALOG,
            file_types=(exts,)
        )
        if result and len(result) > 0:
            return json.dumps({"ok": True, "path": result[0]})
        return json.dumps({"ok": False})

    def obf_browse_save(self):
        """Open a save-as dialog for the output .lua file."""
        result = self._window.create_file_dialog(
            webview.SAVE_DIALOG,
            save_filename="obfuscated.lua",
            file_types=("Lua files (*.lua)",)
        )
        if result:
            p = result if isinstance(result, str) else (result[0] if result else "")
            if p:
                return json.dumps({"ok": True, "path": p})
        return json.dumps({"ok": False})

    def obf_open_output(self, path):
        """Open the output file's containing folder."""
        folder = os.path.dirname(path)
        if os.path.isdir(folder):
            subprocess.Popen(["explorer", folder])
        return json.dumps({"ok": True})

    def _emit(self, event, data):
        payload = json.dumps(data).replace("\\", "\\\\").replace("'", "\\'")
        if self._window:
            self._window.evaluate_js(f"window.__bdEvent('{event}', JSON.parse('{payload}'))")

    def browse(self):
        result = self._window.create_file_dialog(webview.FOLDER_DIALOG)
        if result and len(result) > 0:
            return json.dumps({"ok": True, "path": result[0]})
        return json.dumps({"ok": False})


# ─────────────────────────────────────────────
# HTML / CSS / JS UI
# ─────────────────────────────────────────────

HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Build Doctor</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#0e0f11;--surface:#16181c;--surface2:#1e2126;
  --border:#2a2d34;--border2:#383c45;
  --accent:#00d084;--accent2:#00a868;
  --warn:#f5a623;--error:#ff4e4e;--purple:#a78bfa;
  --text:#e2e4e8;--muted:#6b7280;
  --mono:'IBM Plex Mono',monospace;
  --sans:'IBM Plex Sans',sans-serif;
}
body{background:var(--bg);color:var(--text);font-family:var(--sans);font-size:14px;
     height:100vh;display:flex;flex-direction:column;overflow:hidden;user-select:none}

/* ── Titlebar ── */
.titlebar{
  background:var(--surface);border-bottom:1px solid var(--border);
  padding:0 16px;height:42px;display:flex;align-items:center;gap:12px;
  flex-shrink:0;-webkit-app-region:drag;
}
.tb-dot{width:11px;height:11px;border-radius:50%}
.dot-r{background:#ff5f57}.dot-y{background:#febc2e}.dot-g{background:#28c840}
.tb-name{font-family:var(--mono);font-size:13px;font-weight:600;margin-left:8px;letter-spacing:.04em}
.tb-badge{font-family:var(--mono);font-size:10px;background:var(--accent2);color:#000;
          padding:2px 7px;border-radius:3px;font-weight:600;letter-spacing:.06em}
.tb-version{font-family:var(--mono);font-size:10px;color:var(--muted);margin-left:auto}

/* ── Layout ── */
.main{display:flex;flex:1;overflow:hidden}

/* ── Sidebar ── */
.sidebar{
  width:220px;background:var(--surface);border-right:1px solid var(--border);
  display:flex;flex-direction:column;flex-shrink:0;overflow-y:auto;
}
.sb-section{padding:10px 0;border-bottom:1px solid var(--border)}
.sb-label{font-family:var(--mono);font-size:10px;color:var(--muted);
          letter-spacing:.1em;padding:0 14px 7px;font-weight:600}
.sb-item{
  display:flex;align-items:center;gap:9px;padding:7px 14px;
  cursor:pointer;font-size:13px;color:var(--muted);
  transition:background .1s,color .1s;border-left:2px solid transparent;
}
.sb-item:hover{background:var(--surface2);color:var(--text)}
.sb-item.active{background:var(--surface2);color:var(--accent);border-left-color:var(--accent)}
.sb-item svg{flex-shrink:0;opacity:.7}
.sb-item.active svg,.sb-item:hover svg{opacity:1}
.sb-item.sb-fix{color:var(--warn)}
.sb-item.sb-fix:hover{color:var(--warn)}
.sb-item.sb-fix-all{color:var(--purple)}
.sb-item.sb-fix-all:hover{color:var(--purple)}
.status-area{margin-top:auto;padding:12px 14px;border-top:1px solid var(--border)}
.sdot{display:inline-block;width:7px;height:7px;border-radius:50%;margin-right:6px;vertical-align:middle}
.sdot.idle{background:var(--muted)}
.sdot.building{background:var(--warn);animation:pulse 1s ease-in-out infinite}
.sdot.ok{background:var(--accent)}
.sdot.err{background:var(--error)}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.stext{font-family:var(--mono);font-size:11px;color:var(--muted)}

/* ── C++ Creator ── */
.creator-panel{display:flex;flex:1;overflow:hidden;gap:0}
.creator-left{width:260px;flex-shrink:0;border-right:1px solid var(--border);display:flex;flex-direction:column;overflow:hidden;background:var(--surface)}
.creator-mid{flex:1;display:flex;flex-direction:column;overflow:hidden}
.creator-right{width:320px;flex-shrink:0;border-left:1px solid var(--border);display:flex;flex-direction:column;overflow:hidden}
.cr-sec-hdr{font-family:var(--mono);font-size:10px;color:var(--muted);letter-spacing:.1em;font-weight:600;padding:8px 12px 5px;background:var(--surface);border-bottom:1px solid var(--border);flex-shrink:0}
.cr-tmpl-list{overflow-y:auto;flex:1;padding:4px 0}
.cr-tmpl-item{padding:7px 12px;cursor:pointer;border-left:2px solid transparent;transition:all .1s}
.cr-tmpl-item:hover{background:var(--surface2)}
.cr-tmpl-item.active{background:var(--surface2);border-left-color:var(--accent)}
.cr-tmpl-name{font-size:12px;font-weight:600;color:var(--text)}
.cr-tmpl-desc{font-size:11px;color:var(--muted);margin-top:2px}
.cr-options{padding:10px 12px;display:flex;flex-direction:column;gap:7px;border-top:1px solid var(--border);flex-shrink:0}
.cr-row{display:flex;align-items:center;gap:6px}
.cr-label{font-family:var(--mono);font-size:10px;color:var(--muted);width:70px;flex-shrink:0;letter-spacing:.04em}
.cr-input{flex:1;background:var(--surface2);border:1px solid var(--border);border-radius:3px;color:var(--text);font-family:var(--mono);font-size:11px;padding:4px 8px;outline:none}
.cr-input:focus{border-color:var(--accent)}
.cr-select{flex:1;background:var(--surface2);border:1px solid var(--border);border-radius:3px;color:var(--text);font-family:var(--mono);font-size:11px;padding:3px 6px;outline:none}
.cr-actions{padding:10px 12px;display:flex;gap:6px;flex-shrink:0;flex-wrap:wrap;border-top:1px solid var(--border)}
.code-editor-wrap{flex:1;display:flex;flex-direction:column;overflow:hidden}
.code-editor-bar{background:var(--surface);border-bottom:1px solid var(--border);padding:5px 12px;font-family:var(--mono);font-size:10px;color:var(--muted);display:flex;align-items:center;gap:8px;flex-shrink:0}
.code-editor{flex:1;width:100%;background:#0a0b0d;color:#e2e4e8;font-family:var(--mono);font-size:12px;line-height:1.55;padding:12px;border:none;outline:none;resize:none;overflow-y:auto}
.cr-log{flex:1;overflow-y:auto;background:#0a0b0d;padding:10px 12px;font-family:var(--mono);font-size:11px;line-height:1.5}
.cr-status-bar{padding:7px 12px;background:var(--surface);border-top:1px solid var(--border);display:flex;align-items:center;gap:8px;flex-shrink:0;font-family:var(--mono);font-size:11px}
.cr-exe-display{color:var(--accent);flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:10px}

/* ── Content ── */
.content{flex:1;display:flex;flex-direction:column;overflow:hidden}

/* ── Toolbar ── */
.toolbar{
  background:var(--surface);border-bottom:1px solid var(--border);
  padding:9px 14px;display:flex;align-items:center;gap:9px;flex-shrink:0;
  flex-wrap:wrap;
}
.path-label{font-family:var(--mono);font-size:11px;color:var(--muted);
            white-space:nowrap;letter-spacing:.05em}
.path-input{
  flex:1;background:var(--surface2);border:1px solid var(--border);
  border-radius:4px;color:var(--text);font-family:var(--mono);font-size:12px;
  padding:5px 10px;outline:none;transition:border-color .15s;min-width:0;
}
.path-input:focus{border-color:var(--accent)}
.path-input::placeholder{color:var(--muted)}
.btn{
  font-family:var(--mono);font-size:12px;font-weight:600;
  padding:5px 13px;border-radius:4px;border:1px solid var(--border2);
  cursor:pointer;transition:all .12s;white-space:nowrap;
  letter-spacing:.03em;background:transparent;color:var(--muted);
}
.btn:hover{border-color:var(--accent);color:var(--accent)}
.btn:active{transform:scale(.97)}
.btn-primary{background:var(--accent);color:#000;border-color:var(--accent)}
.btn-primary:hover{background:var(--accent2);border-color:var(--accent2);color:#000}
.btn-primary:disabled{background:var(--surface2);color:var(--muted);
                       border-color:var(--border);cursor:not-allowed;transform:none}
.btn-warn{border-color:var(--warn);color:var(--warn)}
.btn-warn:hover{background:rgba(245,166,35,.1);color:var(--warn);border-color:var(--warn)}
.btn-purple{border-color:var(--purple);color:var(--purple)}
.btn-purple:hover{background:rgba(167,139,250,.1);color:var(--purple);border-color:var(--purple)}

/* ── Panels ── */
.panels{display:flex;flex:1;overflow:hidden}
.panel-left{flex:0 0 270px;border-right:1px solid var(--border);display:flex;flex-direction:column;overflow:hidden}
.panel-right{flex:1;display:flex;flex-direction:column;overflow:hidden}
.panel-header{
  background:var(--surface);border-bottom:1px solid var(--border);padding:7px 14px;
  font-family:var(--mono);font-size:10px;color:var(--muted);letter-spacing:.1em;font-weight:600;
  display:flex;align-items:center;justify-content:space-between;flex-shrink:0;
}
.ph-badge{
  background:var(--surface2);border:1px solid var(--border);border-radius:10px;
  font-size:10px;padding:1px 7px;font-family:var(--mono);
}

/* ── File Tree ── */
.file-tree{overflow-y:auto;flex:1;padding:6px 0}
.tree-group{margin-bottom:2px}
.tree-ext{
  font-family:var(--mono);font-size:10px;padding:3px 14px;letter-spacing:.08em;
  display:flex;align-items:center;gap:6px;font-weight:600;
}
.tree-file{
  font-family:var(--mono);font-size:11px;color:var(--muted);
  padding:2px 14px 2px 22px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;
  cursor:default;line-height:1.6;
}
.tree-file:hover{color:var(--text);background:var(--surface2)}
.tree-strategy{
  margin:8px 10px;padding:7px 10px;background:var(--surface2);border:1px solid var(--border);
  border-radius:4px;font-family:var(--mono);font-size:10px;color:var(--muted);line-height:1.7;
}
.tree-strategy span{color:var(--accent)}
.tree-warn{
  margin:4px 10px;padding:6px 10px;background:rgba(245,166,35,.08);
  border:1px solid rgba(245,166,35,.3);border-radius:4px;
  font-family:var(--mono);font-size:10px;color:var(--warn);line-height:1.6;
}
.empty-msg{padding:18px 14px;font-family:var(--mono);font-size:11px;color:var(--muted);line-height:1.8}

/* ── Terminal ── */
.terminal{
  flex:1;overflow-y:auto;padding:12px 16px;
  font-family:var(--mono);font-size:12px;line-height:1.65;background:var(--bg);
}
.l-default{color:#9ba3af}.l-info{color:var(--accent)}.l-warn{color:var(--warn)}
.l-error{color:var(--error)}.l-dim{color:var(--muted)}.l-heading{color:var(--text);font-weight:600}
.l-purple{color:var(--purple)}
.cursor{display:inline-block;width:8px;height:13px;background:var(--accent);
        vertical-align:middle;animation:blink 1.1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}

/* ── Diagnosis Panel ── */
.diag-panel{border-top:1px solid var(--border);background:var(--surface);flex-shrink:0}
.diag-hdr{
  padding:7px 14px;font-family:var(--mono);font-size:10px;color:var(--muted);
  letter-spacing:.1em;font-weight:600;display:flex;align-items:center;
  gap:8px;cursor:pointer;border-bottom:1px solid transparent;
}
.diag-hdr.open{border-bottom-color:var(--border)}
.diag-body{max-height:150px;overflow-y:auto;padding:8px 12px}
.diag-item{
  display:flex;align-items:flex-start;gap:10px;
  padding:5px 0;border-bottom:1px solid var(--border);font-size:12px;
}
.diag-item:last-child{border-bottom:none}
.diag-badge{
  font-size:10px;font-family:var(--mono);padding:1px 5px;
  border-radius:3px;flex-shrink:0;margin-top:2px;font-weight:600;
}
.badge-fix{background:#1a2e1e;color:var(--accent);border:1px solid var(--accent2)}
.badge-ok{background:#1a2415;color:#4ade80;border:1px solid #166534}
.badge-err{background:#2e1a1a;color:var(--error);border:1px solid #7f1d1d}
.diag-text{font-family:var(--sans);color:var(--text);line-height:1.5}

/* ── Config Panel ── */
.config-panel{padding:18px;overflow-y:auto;display:none;flex:1;flex-direction:column;gap:14px}
.config-panel.show{display:flex}
.cfg-group{
  background:var(--surface2);border:1px solid var(--border);border-radius:6px;padding:14px;
}
.cfg-title{font-family:var(--mono);font-size:10px;color:var(--muted);
           letter-spacing:.08em;margin-bottom:10px;font-weight:600}
.cfg-row{
  display:flex;align-items:center;justify-content:space-between;
  padding:6px 0;border-bottom:1px solid var(--border);gap:12px;
}
.cfg-row:last-child{border-bottom:none}
.cfg-row-label{font-size:13px;color:var(--text)}
.cfg-sel{
  background:var(--surface);border:1px solid var(--border);color:var(--text);
  font-family:var(--mono);font-size:12px;padding:4px 8px;border-radius:4px;outline:none;
}
.cfg-sel:focus{border-color:var(--accent)}
.cfg-tog{
  width:34px;height:18px;background:var(--border2);border-radius:9px;
  cursor:pointer;position:relative;flex-shrink:0;transition:background .2s;
}
.cfg-tog.on{background:var(--accent2)}
.cfg-tog::after{
  content:'';position:absolute;top:3px;left:3px;width:12px;height:12px;
  border-radius:50%;background:#fff;transition:transform .2s;
}
.cfg-tog.on::after{transform:translateX(16px)}

/* ── Scrollbars ── */
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--border2);border-radius:3px}
::-webkit-scrollbar-thumb:hover{background:#4a5060}
</style>
</head>
<body>

<div class="titlebar">
  <div class="tb-dot dot-r"></div>
  <div class="tb-dot dot-y"></div>
  <div class="tb-dot dot-g"></div>
  <span class="tb-name">BUILD DOCTOR</span>
  <span class="tb-badge">MSVC</span>
  <span class="tb-version">v9.0</span>
</div>

<div class="main">
  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sb-section">
      <div class="sb-label">WORKSPACE</div>
      <div class="sb-item active" id="nav-build" onclick="showTab('build')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
        </svg>
        Build
      </div>
      <div class="sb-item" id="nav-config" onclick="showTab('config')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="3"/>
          <path d="M19.07 4.93a10 10 0 0 0-14.14 0M4.93 19.07a10 10 0 0 0 14.14 0"/>
          <path d="M12 2v2M12 20v2M2 12h2M20 12h2"/>
        </svg>
        Settings
      </div>
    </div>

    <div class="sb-section">
      <div class="sb-label">C++ CREATOR</div>
      <div class="sb-item" id="nav-creator" onclick="showTab('creator')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>
        </svg>
        New C++ → .EXE
      </div>
    </div>

    <div class="sb-section">
      <div class="sb-label">QUICK ACTIONS</div>
      <div class="sb-item" onclick="doScan()">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        Scan Project
      </div>
      <div class="sb-item" onclick="doGenerate()">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/>
          <line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="12" y2="17"/>
        </svg>
        Gen build.bat
      </div>
      <div class="sb-item" onclick="doClear()">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="3 6 5 6 21 6"/>
          <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
        </svg>
        Clear Output
      </div>
    </div>

    <div class="sb-section">
      <div class="sb-label">C# FIXERS</div>
      <div class="sb-item sb-fix" onclick="doFixCS()" title="Pass 1&2: Remove dead .cs refs + add missing ProjectReferences">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
          <path d="M9 12l2 2 4-4"/>
        </svg>
        Fix CS Files
      </div>
      <div class="sb-item sb-fix" onclick="doFixDupes()" title="Pass 3: Remove duplicate references and empty ItemGroups">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
        </svg>
        Fix Duplicates
      </div>
      <div class="sb-item sb-fix" onclick="doDotnetRestore()" title="Run dotnet restore to fetch NuGet packages">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="1 4 1 10 7 10"/>
          <path d="M3.51 15a9 9 0 1 0 .49-3.5"/>
        </svg>
        NuGet Restore
      </div>
      <div class="sb-item sb-fix-all" onclick="doFixAll()" title="Run ALL C# fix passes at once">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>
        </svg>
        Fix All C# (All Passes)
      </div>
    </div>

    <div class="sb-section">
      <div class="sb-label">C++ FIXERS</div>
      <div class="sb-item sb-fix" onclick="doFixHeaders()" title="Add #pragma once to headers missing include guards">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>
        </svg>
        Fix Header Guards
      </div>
      <div class="sb-item sb-fix" onclick="doFixVcxproj()" title="Sync .vcxproj: add missing ClCompile/ClInclude for disk files, remove dead entries">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/>
          <line x1="12" y1="11" x2="12" y2="17"/><line x1="9" y1="14" x2="15" y2="14"/>
        </svg>
        Sync .vcxproj Items
      </div>
      <div class="sb-item sb-fix" onclick="doFixMsb3202()" title="Pass 13: Generate missing .vcxproj/.csproj referenced in .sln (MSB3202)">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 2H2v20h20V12L12 2z"/><polyline points="12 2 12 12 22 12"/>
          <line x1="9" y1="16" x2="15" y2="16"/><line x1="12" y1="13" x2="12" y2="19"/>
        </svg>
        Fix MSB3202 (Missing Proj)
      </div>
      <div class="sb-item sb-fix" onclick="doFixLibs()" title="Pass 10: Find missing .lib files and inject into vcxproj linker">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/>
        </svg>
        Fix Missing .libs
      </div>
      <div class="sb-item sb-fix" onclick="doFixPch()" title="Pass 11: Create PCH stub or disable precompiled headers">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/>
          <polyline points="13 2 13 9 20 9"/>
        </svg>
        Fix PCH
      </div>

    <div class="sb-section">
      <div class="sb-label">LUA TOOLS</div>
      <div class="sb-item" id="nav-luaobf" onclick="showTab('luaobf')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
        Lua Obfuscator
      </div>
    </div>

    <div class="sb-section">
      <div class="sb-label">AUTOMATION</div>
      <div class="sb-item" style="color:var(--accent)" onclick="doAutoFixLoop()" title="Build → auto-detect errors → fix → retry (up to 3x)">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="1 4 1 10 7 10"/>
          <polyline points="23 20 23 14 17 14"/>
          <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4-4.64 4.36A9 9 0 0 1 3.51 15"/>
        </svg>
        Auto-Fix Loop
      </div>
    </div>
      <span class="sdot idle" id="sdot"></span>
      <span class="stext" id="stext">IDLE</span>
    </div>
  </div>

  <!-- Content -->
  <div class="content">
    <div class="toolbar">
      <span class="path-label">PATH</span>
      <input class="path-input" id="pathInput" type="text" placeholder="C:\MyProject" />
      <button class="btn" onclick="doBrowse()">BROWSE</button>
      <button class="btn" onclick="doScan()">SCAN</button>
      <button class="btn" onclick="doGenerate()">GEN BAT</button>
      <button class="btn btn-warn" onclick="doFixCS()" title="Fix dead .cs refs + missing ProjectRefs">FIX CS</button>
      <button class="btn btn-warn" onclick="doFixDupes()" title="Remove duplicate refs + empty ItemGroups">FIX DUPES</button>
      <button class="btn btn-warn" onclick="doFixHeaders()" title="Add #pragma once to unguarded headers">FIX HDRS</button>
      <button class="btn btn-warn" onclick="doFixIncludes()" title="Fix C1083: find missing headers and inject include paths into .vcxproj">FIX INCS</button>
      <button class="btn btn-warn" onclick="doFixVcxproj()" title="Auto-sync .vcxproj: add missing ClCompile/ClInclude entries for files on disk, remove dead ones">FIX VCXPROJ</button>
      <button class="btn btn-warn" onclick="doFixLuau()" title="Fix Luau C1083: init submodule or clone luau-lang/luau, then patch .vcxproj">FIX LUAU</button>
      <button class="btn btn-warn" onclick="doFixLibs()" title="Pass 10: Find missing .lib files and inject into .vcxproj linker paths">FIX LIBS</button>
      <button class="btn btn-warn" onclick="doFixMsb3202()" title="Pass 13: Generate or stub missing .vcxproj/.csproj referenced in .sln (MSB3202)">FIX MSB3202</button>
      <button class="btn btn-warn" onclick="doFixPch()" title="Pass 11: Create a PCH stub or disable precompiled headers">FIX PCH</button>
      <button class="btn btn-warn" onclick="doFixWinapiSize()" title="Pass 11b: Fix DWORD→SIZE_T for WriteProcessMemory/ReadProcessMemory (C2664)">FIX SIZET</button>
      <button class="btn btn-purple" onclick="doFixAll()" title="Run all C# fix passes">FIX ALL</button>
      <button class="btn" style="border-color:var(--accent);color:var(--accent)" onclick="doAutoFixLoop()" title="Build → auto-detect errors → apply fixes → retry (up to 3 times)">&#9654;&#9654; AUTO-FIX</button>
      <button class="btn btn-primary" id="runBtn" onclick="doRunBuild()">&#9654; RUN BUILD</button>
    </div>

    <!-- Build Tab -->
    <div id="tab-build" class="panels">
      <div class="panel-left">
        <div class="panel-header">
          FILE TREE
          <span class="ph-badge" id="fileCount">0 files</span>
        </div>
        <div class="file-tree" id="fileTree">
          <div class="empty-msg">No project scanned.<br>Enter a path and click SCAN.</div>
        </div>
      </div>
      <div class="panel-right">
        <div class="panel-header">
          OUTPUT
          <span id="buildTime" style="font-size:10px;color:var(--muted)"></span>
        </div>
        <div class="terminal" id="terminal">
          <span class="l-dim">// Build Doctor v3.0 — ready</span><br>
          <span class="l-dim">// Enter a project path and run a build</span><br><br>
          <span class="cursor"></span>
        </div>
        <div class="diag-panel">
          <div class="diag-hdr" id="diagHdr" onclick="toggleDiag()">
            DIAGNOSIS
            <span style="color:var(--accent);font-size:11px" id="diagChev">&#9650;</span>
          </div>
          <div id="diagBody" style="display:none" class="diag-body"></div>
        </div>
      </div>
    </div>

    <!-- Config Tab -->
    <div id="tab-config" class="config-panel">
      <div class="cfg-group">
        <div class="cfg-title">COMPILER FLAGS</div>
        <div class="cfg-row">
          <span class="cfg-row-label">C++ Standard</span>
          <select class="cfg-sel" id="cfgStd">
            <option>/std:c++17</option>
            <option>/std:c++20</option>
            <option>/std:c++14</option>
            <option>/std:c++latest</option>
          </select>
        </div>
        <div class="cfg-row">
          <span class="cfg-row-label">Configuration</span>
          <select class="cfg-sel" id="cfgConf">
            <option>Release</option>
            <option>Debug</option>
            <option>RelWithDebInfo</option>
          </select>
        </div>
        <div class="cfg-row">
          <span class="cfg-row-label">Runtime Linking</span>
          <select class="cfg-sel" id="cfgRuntime">
            <option value="/MT">/MT — static</option>
            <option value="/MD">/MD — dynamic</option>
            <option value="/MTd">/MTd — debug static</option>
            <option value="/MDd">/MDd — debug dynamic</option>
          </select>
        </div>
        <div class="cfg-row">
          <span class="cfg-row-label">Optimization</span>
          <select class="cfg-sel" id="cfgOpt">
            <option value="/O2">/O2 — maximize speed</option>
            <option value="/O1">/O1 — minimize size</option>
            <option value="/Od">/Od — disabled</option>
            <option value="/Ox">/Ox — full optimization</option>
          </select>
        </div>
      </div>
      <div class="cfg-group">
        <div class="cfg-title">BEHAVIOR</div>
        <div class="cfg-row">
          <span class="cfg-row-label">Auto-generate build.bat if missing</span>
          <div class="cfg-tog on" id="togAutoGen" onclick="this.classList.toggle('on')"></div>
        </div>
        <div class="cfg-row">
          <span class="cfg-row-label">Parallel build (/m flag)</span>
          <div class="cfg-tog on" id="togParallel" onclick="this.classList.toggle('on')"></div>
        </div>
      </div>
      <div class="cfg-group">
        <div class="cfg-title">EXTRA INCLUDE PATHS</div>
        <input class="path-input" id="cfgInc" style="width:100%;margin-top:6px"
               placeholder="C:\libs\include;C:\deps\SDL2\include" />
        <div style="font-family:var(--mono);font-size:10px;color:var(--muted);margin-top:6px">
          Semicolon-separated. Added as /I flags.
        </div>
      </div>
      <div class="cfg-group">
        <div class="cfg-title">EXTRA LIB PATHS</div>
        <input class="path-input" id="cfgLib" style="width:100%;margin-top:6px"
               placeholder="C:\libs\lib;C:\deps\SDL2\lib\x64" />
        <div style="font-family:var(--mono);font-size:10px;color:var(--muted);margin-top:6px">
          Semicolon-separated. Added as /LIBPATH flags.
        </div>
      </div>
    </div>

    <!-- C++ Creator Tab -->
    <div id="tab-creator" class="creator-panel" style="display:none">
      <!-- Left: template picker + build options -->
      <div class="creator-left">
        <div class="cr-sec-hdr">TEMPLATES</div>
        <div class="cr-tmpl-list" id="crTmplList">
          <!-- populated by JS -->
        </div>
        <div class="cr-options">
          <div class="cr-row">
            <span class="cr-label">OUT FOLDER</span>
            <input class="cr-input" id="crOutFolder" placeholder="C:\Projects" style="font-size:10px" />
          </div>
          <div class="cr-row">
            <span class="cr-label">NAME</span>
            <input class="cr-input" id="crName" placeholder="MyProject" />
          </div>
          <div class="cr-row">
            <span class="cr-label">STD</span>
            <select class="cr-select" id="crStd">
              <option value="/std:c++17" selected>C++17</option>
              <option value="/std:c++20">C++20</option>
              <option value="/std:c++14">C++14</option>
              <option value="/std:c++latest">C++latest</option>
            </select>
          </div>
          <div class="cr-row">
            <span class="cr-label">CONFIG</span>
            <select class="cr-select" id="crConfig">
              <option value="Release" selected>Release</option>
              <option value="Debug">Debug</option>
            </select>
          </div>
          <div class="cr-row">
            <span class="cr-label">RUNTIME</span>
            <select class="cr-select" id="crRuntime">
              <option value="/MT" selected>/MT (static)</option>
              <option value="/MD">/MD (DLL)</option>
              <option value="/MTd">/MTd (debug static)</option>
              <option value="/MDd">/MDd (debug DLL)</option>
            </select>
          </div>
          <div class="cr-row">
            <span class="cr-label">SUBSYSTEM</span>
            <select class="cr-select" id="crSubsystem">
              <option value="Console" selected>Console</option>
              <option value="Windows">Windows (no console)</option>
            </select>
          </div>
          <div class="cr-row">
            <span class="cr-label">EXTRA LIBS</span>
            <input class="cr-input" id="crExtraLib" placeholder="ws2_32.lib" style="font-size:10px" />
          </div>
          <div class="cr-row">
            <span class="cr-label">EXTRA INC</span>
            <input class="cr-input" id="crExtraInc" placeholder="C:\SDK\include" style="font-size:10px" />
          </div>
        </div>
        <div class="cr-actions">
          <button class="btn btn-primary" id="crBuildBtn" onclick="crCreateAndBuild()" style="flex:1">&#9654; CREATE &amp; BUILD &#8594; .EXE</button>
          <button class="btn" onclick="crCreateOnly()" title="Create project files only, no build" style="flex:1">&#128196; FILES ONLY</button>
        </div>
        <div class="cr-actions" style="padding-top:0">
          <button class="btn" onclick="crBuildExisting()" title="Build an existing project folder with auto-fix loop" style="flex:1">&#9654; BUILD EXISTING</button>
        </div>
      </div>

      <!-- Mid: code editor -->
      <div class="creator-mid">
        <div class="code-editor-wrap">
          <div class="code-editor-bar">
            <span>&#128196;</span>
            <span id="codeFileLabel">main.cpp</span>
            <span style="margin-left:auto;opacity:.5">edit before build</span>
          </div>
          <textarea class="code-editor" id="codeEditor" spellcheck="false" placeholder="// Select a template or type your C++ code here..."></textarea>
        </div>
      </div>

      <!-- Right: build log + status -->
      <div class="creator-right">
        <div class="cr-sec-hdr">BUILD OUTPUT</div>
        <div class="cr-log" id="crLog"><span class="cursor"></span></div>
        <div class="cr-status-bar">
          <span class="sdot idle" id="crStatusDot"></span>
          <span id="crStatusText" style="color:var(--muted)">idle</span>
          <span class="cr-exe-display" id="crExeDisplay"></span>
        </div>
        <div style="padding:8px 12px;display:flex;gap:6px;border-top:1px solid var(--border);flex-shrink:0">
          <button class="btn btn-primary" id="crRunExeBtn" onclick="crRunExe()" style="display:none;flex:1">&#9654; RUN EXE</button>
          <button class="btn" id="crOpenFolderBtn" onclick="crOpenFolder()" style="display:none;flex:1">&#128193; OPEN FOLDER</button>
        </div>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════
         LUA OBFUSCATOR TAB
         ═══════════════════════════════════════════════════════════ -->
    <div id="tab-luaobf" class="panels" style="display:none; flex-direction:column; gap:0; height:100%; overflow:hidden;">

      <!-- Tab header bar -->
      <div style="display:flex; align-items:center; gap:10px; padding:9px 16px; background:var(--panel); border-bottom:1px solid var(--border); flex-shrink:0;">
        <span style="color:var(--accent); font-family:Consolas,monospace; font-size:13px; font-weight:bold; letter-spacing:1px;">⬡ ZUKATECH</span>
        <span style="color:var(--text-dim); font-family:Consolas,monospace; font-size:11px;">Lua Obfuscator</span>
        <div style="flex:1"></div>
        <span id="obfStatusDot" class="sdot idle"></span>
        <span id="obfStatusText" style="color:var(--text-dim); font-size:11px; font-family:Consolas,monospace; margin-left:5px;">IDLE</span>
      </div>

      <!-- Body: config left + log right -->
      <div style="display:flex; flex:1; overflow:hidden; min-height:0;">

        <!-- ── LEFT config pane ────────────────────────────── -->
        <div style="width:320px; min-width:260px; flex-shrink:0; background:var(--panel); border-right:1px solid var(--border); padding:16px 14px; overflow-y:auto; display:flex; flex-direction:column; gap:13px;">

          <!-- Input file -->
          <div>
            <div style="color:var(--text-dim); font-size:10px; font-family:Consolas,monospace; margin-bottom:5px; letter-spacing:.5px; text-transform:uppercase;">Input .lua</div>
            <div style="display:flex; gap:5px;">
              <input id="obfInput" type="text" placeholder="path\to\script.lua"
                style="flex:1; min-width:0; background:#0d0d0d; border:1px solid var(--border); color:var(--text); font-family:Consolas,monospace; font-size:11px; padding:6px 8px; border-radius:3px; outline:none;"/>
              <button onclick="obfBrowseInput()" title="Browse"
                style="background:var(--border); color:var(--text); border:none; padding:5px 9px; cursor:pointer; font-size:13px; border-radius:3px; flex-shrink:0;">…</button>
            </div>
          </div>

          <!-- Output file -->
          <div>
            <div style="color:var(--text-dim); font-size:10px; font-family:Consolas,monospace; margin-bottom:5px; letter-spacing:.5px; text-transform:uppercase;">Output .lua</div>
            <div style="display:flex; gap:5px;">
              <input id="obfOutput" type="text" placeholder="path\to\obfuscated.lua"
                style="flex:1; min-width:0; background:#0d0d0d; border:1px solid var(--border); color:var(--text); font-family:Consolas,monospace; font-size:11px; padding:6px 8px; border-radius:3px; outline:none;"/>
              <button onclick="obfBrowseOutput()" title="Save As"
                style="background:var(--border); color:var(--text); border:none; padding:5px 9px; cursor:pointer; font-size:13px; border-radius:3px; flex-shrink:0;">…</button>
            </div>
          </div>

          <!-- main.lua path -->
          <div>
            <div style="color:var(--text-dim); font-size:10px; font-family:Consolas,monospace; margin-bottom:5px; letter-spacing:.5px; text-transform:uppercase;">ZukaTech main.lua</div>
            <div style="display:flex; gap:5px;">
              <input id="obfMainLua" type="text" placeholder="path\to\main.lua"
                style="flex:1; min-width:0; background:#0d0d0d; border:1px solid var(--border); color:var(--text); font-family:Consolas,monospace; font-size:11px; padding:6px 8px; border-radius:3px; outline:none;"/>
              <button onclick="obfBrowseMainLua()" title="Browse"
                style="background:var(--border); color:var(--text); border:none; padding:5px 9px; cursor:pointer; font-size:13px; border-radius:3px; flex-shrink:0;">…</button>
            </div>
            <div style="color:#444; font-size:10px; margin-top:4px; font-family:Consolas,monospace;">The bundled ZukaTech obfuscator file</div>
          </div>

          <!-- Lua executable -->
          <div>
            <div style="color:var(--text-dim); font-size:10px; font-family:Consolas,monospace; margin-bottom:5px; letter-spacing:.5px; text-transform:uppercase;">Lua Executable</div>
            <input id="obfLuaExe" type="text" value="lua"
              style="width:100%; box-sizing:border-box; background:#0d0d0d; border:1px solid var(--border); color:var(--text); font-family:Consolas,monospace; font-size:11px; padding:6px 8px; border-radius:3px; outline:none;"
              placeholder="lua  /  luajit  /  full path"/>
            <div style="color:#444; font-size:10px; margin-top:4px; font-family:Consolas,monospace;">lua 5.1, luajit, or absolute path</div>
          </div>

          <!-- Divider + run button -->
          <div style="border-top:1px solid var(--border); padding-top:12px; display:flex; flex-direction:column; gap:7px;">
            <button id="obfRunBtn" onclick="doObfuscate()"
              style="background:var(--accent); color:#000; border:none; padding:10px; font-family:Consolas,monospace; font-size:12px; font-weight:bold; cursor:pointer; border-radius:3px; letter-spacing:1px; transition:background .15s;">
              🔒  OBFUSCATE
            </button>
            <button id="obfOpenBtn" onclick="doObfOpenOutput()" style="display:none;
              background:#111; color:var(--accent); border:1px solid var(--accent); padding:7px; font-family:Consolas,monospace; font-size:11px; cursor:pointer; border-radius:3px;">
              📂  Open Output Folder
            </button>
          </div>

          <!-- Result badge -->
          <div id="obfResult" style="display:none; padding:10px 12px; border-radius:3px; font-family:Consolas,monospace; font-size:11px; line-height:1.7;"></div>

          <!-- Pipeline info -->
          <div style="border-top:1px solid var(--border); padding-top:12px;">
            <div style="color:var(--text-dim); font-size:10px; font-family:Consolas,monospace; margin-bottom:7px; letter-spacing:.5px; text-transform:uppercase;">Active Pipeline (Luraph)</div>
            <div style="color:#555; font-size:10px; font-family:Consolas,monospace; line-height:1.9;">
              SplitStrings<br>
              AntiTamper · DynamicXOR<br>
              DynamicDecrypt · DynamicJumps<br>
              ConstantsObfuscator<br>
              NumbersToExpressions<br>
              OpaquePredicates · Vmify<br>
              EncryptStrings · StatementFlattener<br>
              AntiDump · VirtualGlobals<br>
              FakeLoopWrap · WrapInFunction<br>
              Compressor · DeadCodeEliminator
            </div>
          </div>

        </div><!-- /left config -->

        <!-- ── RIGHT log pane ──────────────────────────────── -->
        <div style="flex:1; display:flex; flex-direction:column; min-width:0; background:#0d0d0d;">
          <div style="background:#0a0a0a; border-bottom:1px solid var(--border); padding:5px 14px; display:flex; align-items:center; justify-content:space-between; flex-shrink:0;">
            <span style="color:var(--text-dim); font-size:10px; font-family:Consolas,monospace; letter-spacing:.5px; text-transform:uppercase;">Obfuscator Log</span>
            <button onclick="obfClearLog()"
              style="background:none; border:none; color:#555; font-size:10px; cursor:pointer; font-family:Consolas,monospace; padding:2px 6px;">CLEAR</button>
          </div>
          <div id="obfLog" style="flex:1; overflow-y:auto; padding:10px 14px; font-family:Consolas,monospace; font-size:11px; line-height:1.75; color:var(--text); white-space:pre-wrap; word-break:break-all;">
            <span style="color:#333;">-- ZukaTech Obfuscator ready. Configure paths and press OBFUSCATE. --</span>
          </div>
        </div><!-- /right log -->

      </div><!-- /body flex -->
    </div><!-- /tab-luaobf -->

  </div><!-- /content -->
</div><!-- /main -->

<script>
// ── Event bridge from Python ─────────────────────
window.__bdEvent = function(event, data) {
  if (event === 'log')          appendLine(data.text, data.cls);
  if (event === 'done')         onBuildDone(data);
  if (event === 'autofix_done') onAutoFixDone(data);
  if (event === 'obf_log')      obfAppendLine(data.text, data.cls);
  if (event === 'obf_done')     onObfDone(data);
};

// ── State ────────────────────────────────────────
let diagOpen   = false;
let isBuilding = false;
let buildStart = 0;

const terminal  = document.getElementById('terminal');
const diagBody  = document.getElementById('diagBody');
const diagHdr   = document.getElementById('diagHdr');
const diagChev  = document.getElementById('diagChev');
const sdot      = document.getElementById('sdot');
const stext     = document.getElementById('stext');
const runBtn    = document.getElementById('runBtn');
const buildTime = document.getElementById('buildTime');
const fileCount = document.getElementById('fileCount');
const fileTree  = document.getElementById('fileTree');

// ── Tabs ─────────────────────────────────────────
function showTab(name) {
  ['build','config','creator','luaobf'].forEach(t => {
    const tab = document.getElementById('tab-'+t);
    const nav = document.getElementById('nav-'+t);
    if (tab) { tab.style.display = 'none'; tab.classList.remove('show'); }
    if (nav) nav.classList.remove('active');
  });
  const el = document.getElementById('tab-'+name);
  if (el) { el.style.display = 'flex'; el.classList.add('show'); }
  const nav = document.getElementById('nav-'+name);
  if (nav) nav.classList.add('active');
  if (name === 'creator') loadTemplates();
}

// ── Status ───────────────────────────────────────
function setStatus(s) {
  sdot.className = 'sdot ' + s;
  stext.textContent = {idle:'IDLE',building:'BUILDING...',ok:'BUILD OK',err:'ERRORS FOUND',fixing:'FIXING...'}[s] || s;
}

// ── Terminal ─────────────────────────────────────
function appendLine(text, cls) {
  const cur = terminal.querySelector('.cursor');
  if (cur) cur.remove();
  const span = document.createElement('span');
  span.className = 'l-' + (cls || 'default');
  span.textContent = text;
  terminal.appendChild(span);
  terminal.appendChild(document.createElement('br'));
  const c = document.createElement('span');
  c.className = 'cursor';
  terminal.appendChild(c);
  terminal.scrollTop = terminal.scrollHeight;
}

function clearLog() {
  terminal.innerHTML = '<span class="cursor"></span>';
}

// ── Diagnosis ────────────────────────────────────
function renderDiag(items, success) {
  diagBody.innerHTML = items.map(msg => {
    const isOk     = success && items.length === 1;
    const badgeCls = isOk ? 'badge-ok' : (success ? 'badge-ok' : 'badge-fix');
    const label    = isOk ? 'OK' : 'FIX';
    return `<div class="diag-item">
      <span class="diag-badge ${badgeCls}">${label}</span>
      <span class="diag-text">${msg}</span>
    </div>`;
  }).join('');
}

function toggleDiag() {
  diagOpen = !diagOpen;
  diagBody.style.display = diagOpen ? 'block' : 'none';
  diagChev.innerHTML     = diagOpen ? '&#9660;' : '&#9650;';
  diagHdr.classList.toggle('open', diagOpen);
}

// ── File Tree ─────────────────────────────────────
function renderTree(files, strategy, vcvars, frameworks) {
  const groups = [
    {ext:'.sln',      files:files.sln,                  color:'#4ade80'},
    {ext:'.vcxproj',  files:files.vcxproj,              color:'#60a5fa'},
    {ext:'.cpp/.c',   files:files.cpp.concat(files.c),  color:'#f472b6'},
    {ext:'.h/.hpp',   files:files.headers,              color:'#fbbf24'},
    {ext:'.csproj',   files:files.csproj,               color:'#a78bfa'},
    {ext:'.cs',       files:files.cs,                   color:'#818cf8'},
    {ext:'CMake',     files:files.cmake,                color:'#a78bfa'},
    {ext:'Makefile',  files:files.makefile,             color:'#fb923c'},
  ].filter(g => g.files.length > 0);

  const total = files.cpp.length + files.c.length + files.headers.length +
                files.sln.length + files.vcxproj.length + files.csproj.length +
                files.cs.length  + files.cmake.length   + files.makefile.length;
  fileCount.textContent = total + ' files';

  const treeHtml = groups.map(g => `
    <div class="tree-group">
      <div class="tree-ext">
        <span style="color:${g.color}">${g.ext}</span>
        <span style="color:var(--muted);font-weight:400">(${g.files.length})</span>
      </div>
      ${g.files.map(f => `<div class="tree-file">${f}</div>`).join('')}
    </div>
  `).join('');

  const stratHtml = `
    <div class="tree-strategy">
      Strategy: <span>${strategy}</span><br>
      vcvars64: <span style="color:${vcvars.includes('NOT')?'var(--error)':'var(--accent)'}">${vcvars}</span>
    </div>`;

  let warnHtml = '';
  if (frameworks && frameworks.warnings && frameworks.warnings.length > 0) {
    warnHtml = frameworks.warnings.map(w =>
      `<div class="tree-warn">&#9888; ${w}</div>`
    ).join('');
  }

  fileTree.innerHTML = stratHtml + warnHtml + treeHtml;
}

// ── Get config from settings UI ──────────────────
function getConfig() {
  return {
    std:       document.getElementById('cfgStd').value,
    config:    document.getElementById('cfgConf').value,
    runtime:   document.getElementById('cfgRuntime').value,
    opt:       document.getElementById('cfgOpt').value,
    parallel:  document.getElementById('togParallel').classList.contains('on'),
    extraInc:  document.getElementById('cfgInc').value,
    extraLib:  document.getElementById('cfgLib').value,
  };
}

// ── Helper: render fix action lines ──────────────
function renderFixActions(actions) {
  actions.forEach(line => {
    let cls;
    if (!line) { cls = 'dim'; }
    else if (line.startsWith('[FIXED')) { cls = 'info'; }
    else if (line.startsWith('[ERROR]') || line.startsWith('[SKIP]')) { cls = 'error'; }
    else if (line.startsWith('===')) { cls = 'heading'; }
    else if (line.startsWith('[OK]')) { cls = 'dim'; }
    else { cls = 'default'; }
    appendLine(line, cls);
  });
}

// ── Actions ──────────────────────────────────────
async function doBrowse() {
  const res = JSON.parse(await window.pywebview.api.browse());
  if (res.ok) document.getElementById('pathInput').value = res.path;
}

async function doScan() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  clearLog();
  appendLine('[*] Scanning: ' + folder, 'info');
  const res = JSON.parse(await window.pywebview.api.scan(folder));
  if (!res.ok) {
    appendLine('[!] ' + res.error, 'error');
    return;
  }
  renderTree(res.files, res.strategy, res.vcvars, res.frameworks);
  const f   = res.files;
  const src = f.cpp.length + f.c.length;
  appendLine(`[+] Found: ${f.sln.length} sln, ${f.vcxproj.length} vcxproj, `+
             `${f.csproj.length} csproj, ${src} source files, ${f.headers.length} headers, `+
             `${f.cs.length} .cs files`, 'info');
  appendLine('[+] Build strategy: ' + res.strategy, 'info');
  if (res.vcvars.includes('NOT')) {
    appendLine('[!] vcvars64.bat not found — install Visual Studio with C++ workload', 'error');
  } else {
    appendLine('[+] MSVC found: ' + res.vcvars, 'dim');
  }
  if (res.frameworks && res.frameworks.warnings.length > 0) {
    res.frameworks.warnings.forEach(w => appendLine('[!] ' + w, 'warn'));
  }
  if (res.frameworks && Object.keys(res.frameworks.frameworks).length > 0) {
    const fwSummary = Object.entries(res.frameworks.frameworks)
      .map(([k,v]) => `${k}: ${v.join(', ')}`).join(' | ');
    appendLine('[~] Target frameworks: ' + fwSummary, 'dim');
  }
}

async function doGenerate() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  clearLog();
  appendLine('[*] Generating build.bat...', 'info');
  const config = getConfig();
  const res    = JSON.parse(await window.pywebview.api.generate(folder, JSON.stringify(config)));
  if (!res.ok) {
    appendLine('[!] ' + res.error, 'error');
    return;
  }
  appendLine('[+] Generated: ' + res.path, 'info');
  appendLine('', 'dim');
  appendLine('--- build.bat preview ---', 'heading');
  res.preview.split('\n').forEach(l => appendLine(l, 'dim'));
}

async function doFixCS() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Pass 1 & 2: scanning .csproj files for dead refs and missing ProjectReferences...', 'info');
  const res = JSON.parse(await window.pywebview.api.fix_cs_files(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed2001 = res.actions.filter(l => l.startsWith('[FIXED-CS2001]')).length;
  const fixed0246 = res.actions.filter(l => l.startsWith('[FIXED-CS0246]')).length;
  appendLine('', 'dim');
  if (fixed2001 + fixed0246 > 0) {
    if (fixed2001) appendLine(`[+] CS2001: removed ${fixed2001} dead Compile reference(s).`, 'info');
    if (fixed0246) appendLine(`[+] CS0246: added ${fixed0246} missing ProjectReference(s).`, 'info');
    appendLine('[+] Re-run your build now.', 'info');
  } else {
    appendLine('[+] No auto-fixable issues found.', 'dim');
  }
  setStatus('idle');
}

async function doFixDupes() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Pass 3: scanning for duplicate references and empty ItemGroups...', 'info');
  const res = JSON.parse(await window.pywebview.api.fix_duplicate_refs(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed = res.actions.filter(l => l.startsWith('[FIXED')).length;
  appendLine('', 'dim');
  appendLine(fixed > 0
    ? `[+] Fixed ${fixed} issue(s). Re-run your build now.`
    : '[+] No duplicates or empty groups found.', fixed > 0 ? 'info' : 'dim');
  setStatus('idle');
}

async function doFixHeaders() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Scanning C++ headers for missing include guards...', 'info');
  const res = JSON.parse(await window.pywebview.api.fix_cpp_headers(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed = res.actions.filter(l => l.startsWith('[FIXED-HDR]')).length;
  appendLine('', 'dim');
  appendLine(fixed > 0
    ? `[+] Added #pragma once to ${fixed} header(s).`
    : '[+] All headers already have include guards.', fixed > 0 ? 'info' : 'dim');
  setStatus('idle');
}

async function doFixVcxproj() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Pass 9: syncing .vcxproj item lists against files on disk...', 'info');
  appendLine('[~] Adds missing <ClCompile> / <ClInclude> entries, removes dead ones.', 'dim');
  appendLine('', 'dim');
  const res = JSON.parse(await window.pywebview.api.fix_vcxproj_items(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const added = res.actions.filter(l => l.startsWith('[FIXED-ADD]')).length;
  const dead  = res.actions.filter(l => l.startsWith('[FIXED-DEAD]')).length;
  const skipped = res.actions.filter(l => l.startsWith('[SKIP]')).length;
  appendLine('', 'dim');
  if (added > 0 || dead > 0) {
    const parts = [];
    if (added > 0) parts.push(`added ${added} missing entry/entries`);
    if (dead  > 0) parts.push(`removed ${dead} dead entry/entries`);
    appendLine(`[+] .vcxproj synced: ${parts.join(', ')}. Re-run your build now.`, 'info');
  } else if (skipped > 0) {
    appendLine('[!] No .vcxproj files found — check your project path.', 'warn');
  } else {
    appendLine('[+] All .vcxproj item references are already in sync with disk.', 'dim');
  }
  setStatus('idle');
}

async function doFixIncludes() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Scanning for missing C++ include directories (C1083)...', 'info');
  appendLine('[~] Uses last build output to target specific missing headers.', 'dim');
  const res = JSON.parse(await window.pywebview.api.fix_cpp_includes(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed = res.actions.filter(l => l.startsWith('[FIXED-INCS]')).length;
  const warned = res.actions.filter(l => l.startsWith('[WARN]')).length;
  appendLine('', 'dim');
  if (fixed > 0) {
    appendLine(`[+] Patched ${fixed} .vcxproj file(s) with new include paths. Re-run your build now.`, 'info');
  } else if (warned > 0) {
    appendLine(`[!] ${warned} header(s) could not be located — add them manually or check dependencies.`, 'warn');
  } else {
    appendLine('[+] All required include paths already present.', 'dim');
  }
  setStatus('idle');
}

async function doFixLuau() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Luau dependency fix — this may take a while if cloning is needed...', 'info');
  appendLine('[~] Will init git submodule or clone luau-lang/luau, then patch .vcxproj.', 'dim');
  appendLine('', 'dim');
  // Lines stream live via the log event; final actions come back in res.actions
  const res = JSON.parse(await window.pywebview.api.fix_luau(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  const fixed  = res.actions.filter(l => l.startsWith('[FIXED-LUAU]')).length;
  const errors = res.actions.filter(l => l.startsWith('[ERROR]')).length;
  const warned = res.actions.filter(l => l.startsWith('[WARN]')).length;
  appendLine('', 'dim');
  if (errors > 0) {
    appendLine('[!] One or more steps failed — check output above.', 'error');
  } else if (fixed > 0) {
    appendLine(`[+] Luau fixed: ${fixed} .vcxproj patched. Re-run your build now.`, 'info');
  } else if (warned > 0) {
    appendLine('[!] Could not fully auto-fix — see warnings above.', 'warn');
  } else {
    appendLine('[+] Luau include paths already in order.', 'dim');
  }
  setStatus('idle');
}

async function doDotnetRestore() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Running dotnet restore — this may take a moment...', 'info');
  const res = JSON.parse(await window.pywebview.api.run_dotnet_restore(folder));
  (res.output || '').split('\n').forEach(l => {
    const lo = l.toLowerCase();
    if (!l.trim()) return;
    const cls = (lo.includes('error') || lo.includes('fail')) ? 'error'
              : lo.includes('warn') ? 'warn'
              : (lo.includes('restored') || lo.includes('success') || lo.includes('installing')) ? 'info'
              : 'dim';
    appendLine(l.trim(), cls);
  });
  appendLine('', 'dim');
  appendLine(res.ok
    ? '[+] dotnet restore succeeded. Re-run your build now.'
    : '[!] Restore failed — check output above.', res.ok ? 'info' : 'error');
  setStatus('idle');
}

async function doFixAll() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Running ALL C# auto-fix passes...', 'purple');
  appendLine('', 'dim');
  const res = JSON.parse(await window.pywebview.api.fix_all(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed = res.actions.filter(l => l.startsWith('[FIXED')).length;
  appendLine('', 'dim');
  appendLine(fixed > 0
    ? `[+] Total fixed: ${fixed} issue(s) across all passes. Re-run your build now.`
    : '[+] No auto-fixable issues found across all passes.', fixed > 0 ? 'info' : 'dim');
  setStatus('idle');
}

async function doRunBuild() {
  if (isBuilding) return;
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }

  isBuilding = true;
  runBtn.disabled   = true;
  runBtn.textContent = '\u23F3 BUILDING';
  setStatus('building');
  clearLog();
  diagBody.innerHTML = '';
  buildTime.textContent = '';
  buildStart = Date.now();

  appendLine('[*] Starting build: ' + folder, 'info');
  appendLine('', 'dim');

  const config = getConfig();
  await window.pywebview.api.run_build(folder, JSON.stringify(config));
}

function onBuildDone(data) {
  const elapsed = ((Date.now() - buildStart) / 1000).toFixed(2);
  buildTime.textContent = elapsed + 's';

  appendLine('', 'dim');
  appendLine('=== DIAGNOSIS ===', 'heading');
  data.diag.forEach(msg => appendLine('[+] ' + msg, data.success ? 'info' : 'warn'));

  if (data.success && data.exePath) {
    appendLine('', 'dim');
    appendLine('\u2714 BUILD SUCCEEDED', 'info');
    appendLine('\u2192 EXE: ' + data.exePath, 'info');
    if (data.sha256) appendLine('[SHA256] ' + data.sha256, 'dim');
  } else if (data.success) {
    appendLine('', 'dim');
    appendLine('\u2714 BUILD SUCCEEDED (check project output folder for .exe)', 'info');
  }

  if (data.hasLuau) {
    appendLine('', 'dim');
    appendLine('[!] Luau files missing — click FIX LUAU to clone the repo, copy missing .cpp sources, patch include paths, and update your .vcxproj.', 'warn');
  } else if (data.hasC1083) {
    appendLine('', 'dim');
    appendLine('[!] C1083 detected — click FIX INCS to auto-patch include paths in your .vcxproj.', 'warn');
  }
  if (data.hasLnk) {
    appendLine('', 'dim');
    appendLine('[!] LNK errors detected — click FIX LIBS to auto-find and inject missing .lib paths.', 'warn');
  }
  if (data.hasPch) {
    appendLine('', 'dim');
    appendLine('[!] C1010 detected — click FIX PCH to create a PCH stub or disable precompiled headers.', 'warn');
  }
  if (data.hasWinapiSize) {
    appendLine('', 'dim');
    appendLine('[!] C2664 detected — WriteProcessMemory/ReadProcessMemory require SIZE_T* not DWORD*. Click FIX SIZET to auto-patch.', 'warn');
  }

  if (!data.success) {
    appendLine('', 'dim');
    appendLine('[TIP] Click \u25b6\u25b6 AUTO-FIX to automatically detect errors and retry the build.', 'dim');
  }

  renderDiag(data.diag, data.success);
  if (!diagOpen) toggleDiag();

  setStatus(data.success ? 'ok' : 'err');
  isBuilding = false;
  runBtn.disabled   = false;
  runBtn.textContent = '\u25B6 RUN BUILD';
}

function onAutoFixDone(data) {
  const elapsed = ((Date.now() - buildStart) / 1000).toFixed(2);
  buildTime.textContent = elapsed + 's';

  appendLine('', 'dim');
  appendLine('═══ AUTO-FIX LOOP COMPLETE ═══', 'heading');
  if (data.success) {
    appendLine(`\u2714 BUILD SUCCEEDED after ${data.attempts} attempt(s).`, 'info');
    if (data.exePath) appendLine('\u2192 EXE: ' + data.exePath, 'info');
    if (data.sha256)  appendLine('[SHA256] ' + data.sha256, 'dim');
  } else {
    appendLine(`\u2716 BUILD FAILED after ${data.attempts} attempt(s) — manual intervention needed.`, 'error');
    appendLine('[TIP] Check the output above for unfixed errors, or use individual FIX buttons.', 'warn');
  }

  data.diag.forEach(msg => appendLine('[+] ' + msg, data.success ? 'info' : 'warn'));

  renderDiag(data.diag, data.success);
  if (!diagOpen) toggleDiag();

  setStatus(data.success ? 'ok' : 'err');
  isBuilding = false;
  runBtn.disabled   = false;
  runBtn.textContent = '\u25B6 RUN BUILD';
}

async function doFixLibs() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Pass 10: scanning for missing .lib files (LNK errors)...', 'info');
  appendLine('[~] Will search project tree and SDK paths for matching .lib files.', 'dim');
  appendLine('', 'dim');
  const res = JSON.parse(await window.pywebview.api.fix_missing_libs(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed  = res.actions.filter(l => l.startsWith('[FIXED-LIB]')).length;
  const warned = res.actions.filter(l => l.startsWith('[WARN]')).length;
  appendLine('', 'dim');
  if (fixed > 0) {
    appendLine(`[+] Patched ${fixed} .vcxproj entry/entries with lib paths. Re-run build now.`, 'info');
  } else if (warned > 0) {
    appendLine('[!] Some .lib files could not be found — add them manually or install the dependency.', 'warn');
  } else {
    appendLine('[+] All required lib paths already present.', 'dim');
  }
  setStatus('idle');
}

async function doFixPch() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Pass 11: checking precompiled header (PCH) configuration...', 'info');
  const res = JSON.parse(await window.pywebview.api.fix_pch(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed  = res.actions.filter(l => l.startsWith('[FIXED-PCH]')).length;
  appendLine('', 'dim');
  appendLine(fixed > 0
    ? `[+] PCH fixed: ${fixed} action(s) taken. Re-run build now.`
    : '[+] PCH configuration looks fine.', fixed > 0 ? 'info' : 'dim');
  setStatus('idle');
}

async function doFixWinapiSize() {
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }
  setStatus('fixing');
  clearLog();
  appendLine('[*] Pass 11b: fixing DWORD → SIZE_T for WriteProcessMemory/ReadProcessMemory...', 'info');
  appendLine('[~] Patching variables declared as DWORD that are passed as &arg to WPM/RPM.', 'dim');
  appendLine('', 'dim');
  const res = JSON.parse(await window.pywebview.api.fix_winapi_size_t(folder));
  if (!res.ok) { appendLine('[!] ' + res.error, 'error'); setStatus('idle'); return; }
  renderFixActions(res.actions);
  const fixed = res.actions.filter(l => l.startsWith('[FIXED-SIZET]')).length;
  appendLine('', 'dim');
  appendLine(fixed > 0
    ? `[+] Fixed: ${fixed} DWORD declaration(s) changed to SIZE_T. Re-run build now.`
    : '[+] No DWORD → SIZE_T changes needed (or already fixed).', fixed > 0 ? 'info' : 'dim');
  setStatus('idle');
}

async function doAutoFixLoop() {
  if (isBuilding) return;
  const folder = document.getElementById('pathInput').value.trim();
  if (!folder) { appendLine('[!] Enter a project path first.', 'error'); return; }

  isBuilding = true;
  runBtn.disabled   = true;
  runBtn.textContent = '\u23F3 BUILDING';
  setStatus('building');
  clearLog();
  diagBody.innerHTML = '';
  buildTime.textContent = '';
  buildStart = Date.now();

  appendLine('[*] AUTO-FIX LOOP started — will build, detect errors, fix, and retry.', 'info');
  appendLine('[~] Max 3 fix+retry attempts before giving up.', 'dim');
  appendLine('', 'dim');

  const config = getConfig();
  await window.pywebview.api.auto_fix_loop(folder, JSON.stringify(config), 3);
}

function doClear() {
  clearLog();
  diagBody.innerHTML    = '';
  buildTime.textContent = '';
  setStatus('idle');
}

// ══════════════════════════════════════════════════════════
// C++ Creator JS
// ══════════════════════════════════════════════════════════
let selectedTmpl = 'blank';
let crBuilding   = false;
let crLastFolder = '';
let crLastExe    = '';
let crBuildStart = 0;
let crBuildBtn;

function crAppendLog(text, cls) {
  const log = document.getElementById('crLog');
  const cur = log.querySelector('.cursor');
  if (cur) cur.remove();
  const span = document.createElement('span');
  span.className = 'l-' + (cls || 'default');
  span.textContent = text;
  log.appendChild(span);
  log.appendChild(document.createElement('br'));
  const c = document.createElement('span');
  c.className = 'cursor';
  log.appendChild(c);
  log.scrollTop = log.scrollHeight;
}

function crClearLog() {
  document.getElementById('crLog').innerHTML = '<span class="cursor"></span>';
}

async function loadTemplates() {
  try {
    const r = JSON.parse(await window.pywebview.api.get_templates());
    if (!r.ok) return;
    const list = document.getElementById('crTmplList');
    list.innerHTML = '';
    for (const t of r.templates) {
      const div = document.createElement('div');
      div.className = 'cr-tmpl-item' + (t.id === selectedTmpl ? ' active' : '');
      div.dataset.id = t.id;
      div.innerHTML = `<div class="cr-tmpl-name">${t.label}</div><div class="cr-tmpl-desc">${t.desc}</div>`;
      div.onclick = () => selectTemplate(t.id);
      list.appendChild(div);
    }
  } catch(e) { console.error('loadTemplates:', e); }
}

function selectTemplate(id) {
  selectedTmpl = id;
  document.querySelectorAll('.cr-tmpl-item').forEach(el => {
    el.classList.toggle('active', el.dataset.id === id);
  });
  // Auto-populate extraLib for templates that need it
  const libHints = {
    'network_scanner': 'ws2_32.lib',
    'winapi_window':   'user32.lib;gdi32.lib',
    'dll_inject':      '',
    'hook_engine':     'user32.lib',
    'process_injector':'',
    'imgui_dx11':         'd3d11.lib;dxgi.lib;user32.lib;gdi32.lib',
    'imgui_dx11_docking': 'd3d11.lib;dxgi.lib;user32.lib;gdi32.lib',
  };
  const incHints = {
    'imgui_dx11':         'imgui;imgui/backends',
    'imgui_dx11_docking': 'imgui;imgui/backends',
  };
  if (id in libHints) {
    const el = document.getElementById('crExtraLib');
    if (!el.value.trim()) el.value = libHints[id];
  }
  if (id in incHints) {
    const el = document.getElementById('crExtraInc');
    if (!el.value.trim()) el.value = incHints[id];
  }
}

// Register the cr_build_done event handler
window.__bdEvent = window.__bdEvent || function(event, data) {
  if (event === 'cr_build_done') {
    onCrBuildDone(data);
    return;
  }
  // existing handler
  if (typeof onBdEvent === 'function') onBdEvent(event, data);
};

// Wrap existing __bdEvent
(function() {
  const orig = window.__bdEvent;
  window.__bdEvent = function(event, data) {
    if (event === 'cr_build_done') { onCrBuildDone(data); return; }
    orig(event, data);
  };
})();

function onCrBuildDone(data) {
  if (!crBuildBtn) crBuildBtn = document.getElementById('crBuildBtn');
  const elapsed = ((Date.now() - crBuildStart) / 1000).toFixed(1);
  crAppendLog('', 'dim');
  crAppendLog(`[~] Build finished in ${elapsed}s`, 'dim');

  const crDot  = document.getElementById('crStatusDot');
  const crTxt  = document.getElementById('crStatusText');
  const exeDisp= document.getElementById('crExeDisplay');

  if (data.ok) {
    crDot.className = 'sdot ok';
    crTxt.textContent = 'build succeeded ✔';
    crLastFolder = data.folder;
    crLastExe    = data.exe_path;
    if (data.exe_path) {
      exeDisp.textContent = data.exe_path;
      document.getElementById('crRunExeBtn').style.display = '';
    }
    if (data.folder) {
      document.getElementById('crOpenFolderBtn').style.display = '';
    }
  } else {
    crDot.className = 'sdot err';
    crTxt.textContent = 'build failed ✖';
    crLastFolder = data.folder || '';
    if (data.folder) document.getElementById('crOpenFolderBtn').style.display = '';
  }

  if (crBuildBtn) {
    crBuildBtn.disabled = false;
    crBuildBtn.textContent = '▶ CREATE & BUILD → .EXE';
  }
  crBuilding = false;
}

function crSetBuilding(yes) {
  crBuilding = yes;
  if (!crBuildBtn) crBuildBtn = document.getElementById('crBuildBtn');
  if (crBuildBtn) {
    crBuildBtn.disabled = yes;
    crBuildBtn.textContent = yes ? '⏳ BUILDING…' : '▶ CREATE & BUILD → .EXE';
  }
  const dot = document.getElementById('crStatusDot');
  const txt = document.getElementById('crStatusText');
  dot.className = 'sdot ' + (yes ? 'building' : 'idle');
  txt.textContent = yes ? 'building…' : 'idle';
}

async function crCreateAndBuild() {
  if (crBuilding) return;
  crBuildBtn = document.getElementById('crBuildBtn');
  const outFolder = document.getElementById('crOutFolder').value.trim();
  const name      = document.getElementById('crName').value.trim() || 'MyProject';
  const std       = document.getElementById('crStd').value;
  const config    = document.getElementById('crConfig').value;
  const runtime   = document.getElementById('crRuntime').value;
  const subsystem = document.getElementById('crSubsystem').value;
  const extraLib  = document.getElementById('crExtraLib').value.trim();
  const extraInc  = document.getElementById('crExtraInc').value.trim();
  const customCode= document.getElementById('codeEditor').value;

  if (!outFolder) {
    crAppendLog('[!] Output folder is required.', 'error');
    return;
  }

  crSetBuilding(true);
  crClearLog();
  crBuildStart = Date.now();
  document.getElementById('crRunExeBtn').style.display = 'none';
  document.getElementById('crOpenFolderBtn').style.display = 'none';
  document.getElementById('crExeDisplay').textContent = '';

  crAppendLog(`[*] Project: ${name}  Template: ${selectedTmpl}`, 'info');
  crAppendLog(`[*] Config: ${config}  Std: ${std}  Runtime: ${runtime}`, 'dim');

  await window.pywebview.api.create_and_build(
    outFolder, name, selectedTmpl, customCode,
    std, config, runtime, subsystem, extraLib, extraInc
  );
}

async function crCreateOnly() {
  const outFolder = document.getElementById('crOutFolder').value.trim();
  const name      = document.getElementById('crName').value.trim() || 'MyProject';
  const std       = document.getElementById('crStd').value;
  const config    = document.getElementById('crConfig').value;
  const runtime   = document.getElementById('crRuntime').value;
  const subsystem = document.getElementById('crSubsystem').value;
  const extraLib  = document.getElementById('crExtraLib').value.trim();
  const extraInc  = document.getElementById('crExtraInc').value.trim();

  if (!outFolder) { crAppendLog('[!] Output folder required.', 'error'); return; }

  crClearLog();
  crAppendLog('[*] Creating project files...', 'info');

  try {
    const r = JSON.parse(await window.pywebview.api.create_project(
      outFolder, name, selectedTmpl, std, config, runtime, subsystem, extraLib, extraInc
    ));

    if (!r.ok) { crAppendLog('[!] ' + r.error, 'error'); return; }

    crLastFolder = r.folder;
    for (const f of r.files)
      crAppendLog(`[+] Created: ${f}`, 'info');
    crAppendLog(`[+] Project folder: ${r.folder}`, 'info');
    if (r.setup_note) {
      crAppendLog('', 'dim');
      crAppendLog('[!] SETUP REQUIRED:', 'warn');
      for (const line of r.setup_note.split('\n'))
        crAppendLog('    ' + line, 'warn');
      crAppendLog('', 'dim');
    }
    crAppendLog('[~] Open the folder or use Build Existing to compile.', 'dim');

    document.getElementById('crOpenFolderBtn').style.display = '';
    document.getElementById('crStatusDot').className = 'sdot ok';
    document.getElementById('crStatusText').textContent = 'files created ✔';

    // Load code into editor
    const codeRes = JSON.parse(await window.pywebview.api.read_cpp(r.folder));
    if (codeRes.ok) {
      document.getElementById('codeEditor').value = codeRes.code;
      document.getElementById('codeFileLabel').textContent = codeRes.path.split('\\').pop();
    }
  } catch(e) {
    crAppendLog('[!] ' + e, 'error');
  }
}

async function crBuildExisting() {
  const folder = document.getElementById('crOutFolder').value.trim();
  if (!folder) { crAppendLog('[!] Enter a project folder.', 'error'); return; }

  const config  = document.getElementById('crConfig').value;
  const std     = document.getElementById('crStd').value;
  const runtime = document.getElementById('crRuntime').value;
  const cfg = { config, std, runtime, opt: '/O2', parallel: true, extraInc:'', extraLib:'' };

  if (crBuilding) return;
  crSetBuilding(true);
  crClearLog();
  crBuildStart = Date.now();

  crAppendLog('[*] Building existing project: ' + folder, 'info');
  await window.pywebview.api.auto_fix_loop_v2(folder, JSON.stringify(cfg), 3);
}

async function crOpenFolder() {
  if (crLastFolder)
    await window.pywebview.api.open_folder(crLastFolder);
}

async function crRunExe() {
  if (crLastExe)
    await window.pywebview.api.run_exe(crLastExe);
}

// Auto-save code edits to disk when folder is known
document.addEventListener('DOMContentLoaded', () => {
  const editor = document.getElementById('codeEditor');
  if (editor) {
    editor.addEventListener('blur', async () => {
      if (!crLastFolder) return;
      const code = editor.value;
      const codeRes = JSON.parse(await window.pywebview.api.read_cpp(crLastFolder));
      if (codeRes.ok) await window.pywebview.api.write_cpp(codeRes.path, code);
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
//  LUA OBFUSCATOR TAB — JavaScript
// ═══════════════════════════════════════════════════════════════════

let obfRunning  = false;
let obfLastOut  = '';

// ── Log helpers ──────────────────────────────────────────────────────
function obfAppendLine(text, cls) {
  const log = document.getElementById('obfLog');
  if (!log) return;

  // Clear placeholder on first real line
  if (log.children.length === 1 && log.children[0].style.color === 'rgb(51, 51, 51)') {
    log.innerHTML = '';
  }

  const colorMap = {
    heading:  'var(--accent)',
    info:     'var(--accent)',
    error:    '#ff4f4f',
    warn:     '#f0a030',
    dim:      '#444',
    default:  'var(--text)',
  };
  const span = document.createElement('span');
  span.style.color = colorMap[cls] || colorMap.default;
  span.textContent = text;
  log.appendChild(span);
  log.appendChild(document.createElement('br'));
  log.scrollTop = log.scrollHeight;
}

function obfClearLog() {
  const log = document.getElementById('obfLog');
  if (log) log.innerHTML = '<span style="color:#333;">-- cleared --</span>';
}

// ── Status helpers ───────────────────────────────────────────────────
function obfSetStatus(s) {
  const dot  = document.getElementById('obfStatusDot');
  const txt  = document.getElementById('obfStatusText');
  const map  = { idle: ['idle','IDLE'], running: ['building','OBFUSCATING...'], ok: ['ok','DONE ✓'], err: ['err','FAILED ✖'] };
  const [cls, label] = map[s] || ['idle', s];
  if (dot) dot.className = 'sdot ' + cls;
  if (txt) txt.textContent = label;
}

function obfSetRunning(yes) {
  obfRunning = yes;
  const btn = document.getElementById('obfRunBtn');
  if (btn) {
    btn.disabled   = yes;
    btn.textContent = yes ? '⏳  OBFUSCATING…' : '🔒  OBFUSCATE';
    btn.style.background = yes ? '#1a1a1a' : 'var(--accent)';
    btn.style.color      = yes ? '#444'    : '#000';
  }
  obfSetStatus(yes ? 'running' : 'idle');
}

// ── File browser helpers ─────────────────────────────────────────────
async function obfBrowseInput() {
  const r = JSON.parse(await window.pywebview.api.obf_browse_file('Select input Lua script', 'Lua files (*.lua)'));
  if (r.ok) {
    document.getElementById('obfInput').value = r.path;
    // Auto-fill output if empty
    const outEl = document.getElementById('obfOutput');
    if (!outEl.value.trim()) {
      const dir  = r.path.replace(/[/\\][^/\\]+$/, '');
      const base = r.path.replace(/.*[/\\]/, '').replace(/\.lua$/i, '');
      outEl.value = dir + '\\' + base + '_obfuscated.lua';
    }
  }
}

async function obfBrowseOutput() {
  const r = JSON.parse(await window.pywebview.api.obf_browse_save());
  if (r.ok) document.getElementById('obfOutput').value = r.path;
}

async function obfBrowseMainLua() {
  const r = JSON.parse(await window.pywebview.api.obf_browse_file('Select ZukaTech main.lua', 'Lua files (*.lua)'));
  if (r.ok) document.getElementById('obfMainLua').value = r.path;
}

// ── Main obfuscate action ────────────────────────────────────────────
async function doObfuscate() {
  if (obfRunning) return;

  const inputPath  = document.getElementById('obfInput').value.trim();
  const outputPath = document.getElementById('obfOutput').value.trim();
  const mainLua    = document.getElementById('obfMainLua').value.trim();
  const luaExe     = document.getElementById('obfLuaExe').value.trim() || 'lua';

  // Client-side validation
  if (!inputPath) {
    obfAppendLine('[!] Input file path is required.', 'error'); return;
  }
  if (!outputPath) {
    obfAppendLine('[!] Output file path is required.', 'error'); return;
  }
  if (!mainLua) {
    obfAppendLine('[!] ZukaTech main.lua path is required.', 'error'); return;
  }

  // Reset UI
  const resultEl = document.getElementById('obfResult');
  resultEl.style.display = 'none';
  document.getElementById('obfOpenBtn').style.display = 'none';
  obfClearLog();
  obfSetRunning(true);

  obfLastOut = outputPath;
  await window.pywebview.api.obfuscate_lua(inputPath, outputPath, luaExe, mainLua);
}

// ── Done handler (called by event bridge) ───────────────────────────
function onObfDone(data) {
  obfSetRunning(false);
  const resultEl = document.getElementById('obfResult');
  const openBtn  = document.getElementById('obfOpenBtn');

  if (data.ok) {
    obfSetStatus('ok');
    resultEl.style.display    = 'block';
    resultEl.style.background = '#0a1a0a';
    resultEl.style.border     = '1px solid #1a4a1a';
    resultEl.style.color      = 'var(--accent)';
    resultEl.innerHTML = `✓ Success<br><span style="color:#888;font-size:10px;">${data.output}</span><br><span style="color:#666;font-size:10px;">${data.kb} KB</span>`;
    openBtn.style.display = '';
  } else {
    obfSetStatus('err');
    resultEl.style.display    = 'block';
    resultEl.style.background = '#1a0a0a';
    resultEl.style.border     = '1px solid #4a1a1a';
    resultEl.style.color      = '#ff4f4f';
    resultEl.innerHTML = '✖ Obfuscation failed<br><span style="color:#888;font-size:10px;">Check the log for details.</span>';
    openBtn.style.display = 'none';
  }
}

// ── Open output folder ───────────────────────────────────────────────
async function doObfOpenOutput() {
  if (obfLastOut) await window.pywebview.api.obf_open_output(obfLastOut);
}

</script>
</body>
</html>
"""


# ─────────────────────────────────────────────
# Entry Point
# ─────────────────────────────────────────────

def main():
    api    = Api()
    window = webview.create_window(
        APP_TITLE,
        html=HTML,
        js_api=api,
        width=1160,
        height=720,
        min_size=(900, 580),
        background_color="#0e0f11",
    )
    api.set_window(window)
    webview.start(debug=False)


if __name__ == "__main__":
  main()
