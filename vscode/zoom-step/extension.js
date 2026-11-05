// Zooms the window by 10% a step, where VS Code's own zoom steps by
// 20%.  VS Code scales the window by 1.2 to the power of
// window.zoomLevel and takes no step size, so this adds or takes away
// the level that scales by 1.1.  See ../README.md.
const vscode = require("vscode");

const STEP = Math.log(1.1) / Math.log(1.2);

function zoom(direction) {
  const window = vscode.workspace.getConfiguration("window");
  const level = window.get("zoomLevel", 0) + direction * STEP;
  // Rounded, so stepping in and back out lands on the same level.
  return window.update(
    "zoomLevel",
    Math.round(level * 10000) / 10000,
    vscode.ConfigurationTarget.Global,
  );
}

exports.activate = (context) => {
  context.subscriptions.push(
    vscode.commands.registerCommand("zoomStep.in", () => zoom(1)),
    vscode.commands.registerCommand("zoomStep.out", () => zoom(-1)),
  );
};

exports.deactivate = () => {};
