function exists(path: string): boolean {
  try {
    Deno.lstatSync(path);
    return true;
  } catch {
    return false;
  }
}

function isDirOrSymlink(entries: Deno.DirEntry[], name: string): boolean {
  return entries.some((entry) =>
    (entry.isDirectory || entry.isSymlink) && entry.name === name
  );
}

function copyPath(source: string, target: string, replace = false): void {
  if (replace && exists(target)) {
    Deno.removeSync(target, { recursive: true });
  }
  const result = new Deno.Command("/bin/cp", {
    args: ["-a", source, target],
    stdout: "null",
    stderr: "piped",
  }).outputSync();
  if (!result.success) {
    throw new Error(
      "cp failed: " + new TextDecoder().decode(result.stderr),
    );
  }
}

function ensureSymlink(target: string, path: string): void {
  if (!exists(path)) {
    const parent = path.substring(0, path.lastIndexOf("/")) || "/";
    Deno.mkdirSync(parent, {
      recursive: true,
    });
    Deno.symlinkSync(target, path);
  }
}

function hydrateAndLink(distName: string, sbbsName: string): void {
  const sbbsEntries = Array.from(Deno.readDirSync("/sbbs"));
  const dataEntries = Array.from(Deno.readDirSync("/sbbs-data"));
  if (isDirOrSymlink(sbbsEntries, sbbsName)) {
    return;
  }
  if (!isDirOrSymlink(dataEntries, sbbsName)) {
    const target = "/sbbs-data/" + sbbsName;
    if (distName) {
      copyPath("/sbbs/dist/" + distName, target);
    } else {
      Deno.mkdirSync(target, { recursive: true });
    }
  }
  ensureSymlink("/sbbs-data/" + sbbsName, "/sbbs/" + sbbsName);
}

function checkNode(nodes: Deno.DirEntry[], number: number): void {
  if (!isDirOrSymlink(nodes, "node" + number)) {
    copyPath("/sbbs/dist/node1", "/sbbs-data/nodes/node" + number);
  }
  ensureSymlink(
    "/sbbs-data/nodes/node" + number,
    "/sbbs/node" + number,
  );
}

async function checkNodes(): Promise<void> {
  if (!exists("/sbbs-data/nodes")) {
    Deno.mkdirSync("/sbbs-data/nodes", { recursive: true });
  }
  const nodes = Array.from(Deno.readDirSync("/sbbs-data/nodes"));
  let lastNode = nodes
    .map((entry) => Number(entry.name.replace("node", "")))
    .filter((number) => Number.isFinite(number))
    .sort((a, b) => b - a)[0] || 4;

  try {
    const result = await new Deno.Command("/sbbs/exec/jsexec", {
      args: ["-n", "-r", "write(system.nodes)"],
      stdout: "piped",
      stderr: "piped",
    }).output();
    const stdout = new TextDecoder().decode(result.stdout).trim();
    const stderr = new TextDecoder().decode(result.stderr);
    if (result.success && !stderr && Number(stdout) > 0) {
      lastNode = Number(stdout);
    }
  } catch {
    // The saved node directories remain the fallback if jsexec cannot run.
  }

  for (let number = 1; number <= lastNode; number++) {
    checkNode(nodes, number);
  }
}

function backupDefaults(): void {
  Deno.mkdirSync("/sbbs-data/backup/defaults", { recursive: true });
  copyPath("/sbbs/exec", "/sbbs-data/backup/defaults/exec", true);
  for (const entry of Deno.readDirSync("/sbbs/dist")) {
    copyPath(
      "/sbbs/dist/" + entry.name,
      "/sbbs-data/backup/defaults/" + entry.name,
      true,
    );
  }
}

async function runUpgradeJs(): Promise<void> {
  console.log("Running Synchronet upgrade script");
  const result = await new Deno.Command("/sbbs/exec/jsexec", {
    args: ["-n", "/sbbs/exec/update.js"],
    stdout: "piped",
    stderr: "piped",
  }).output();
  const stdout = new TextDecoder().decode(result.stdout);
  const stderr = new TextDecoder().decode(result.stderr);
  if (stdout) console.log(stdout);
  if (!result.success || stderr) {
    if (stderr) console.error(stderr);
    throw new Error("Synchronet update.js failed");
  }
}

async function upgrade(existingVersion: string): Promise<void> {
  console.log("Backing up current defaults before upgrade");
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  const oldDat = await Deno.readTextFile("/sbbs/ctrl/text.dat").catch(() => "");
  const newDat = await Deno.readTextFile("/sbbs/dist/ctrl/text.dat").catch(
    () => "",
  );
  if (oldDat && newDat && oldDat !== newDat) {
    Deno.copyFileSync(
      "/sbbs/ctrl/text.dat",
      "/sbbs/ctrl/text.dat." + stamp + ".bak",
    );
    Deno.copyFileSync("/sbbs/dist/ctrl/text.dat", "/sbbs/ctrl/text.dat");
  }

  backupDefaults();
  if (existingVersion) {
    await runUpgradeJs();
  }
  Deno.copyFileSync("/sbbs/exec/version.txt", "/sbbs/ctrl/version.txt");
}

async function main(): Promise<void> {
  console.log("Synchronet container initialization");
  Deno.mkdirSync("/sbbs-data/backup", { recursive: true });
  ensureSymlink("/sbbs-data/backup", "/backup");

  hydrateAndLink("", "data");
  hydrateAndLink("ctrl", "ctrl");
  hydrateAndLink("xtrn", "xtrn");
  hydrateAndLink("text", "text");
  hydrateAndLink("web-ecweb4", "web");
  hydrateAndLink("", "mods");
  hydrateAndLink("", "fido");
  await checkNodes();

  const oldVersion = await Deno.readTextFile("/sbbs/ctrl/version.txt").catch(
    () => "",
  );
  const newVersion = await Deno.readTextFile("/sbbs/exec/version.txt").catch(
    () => "",
  );

  if (newVersion && oldVersion !== newVersion) {
    console.log("New Synchronet version detected");
    console.log(newVersion);
    await upgrade(oldVersion);
  }
}

await main();
