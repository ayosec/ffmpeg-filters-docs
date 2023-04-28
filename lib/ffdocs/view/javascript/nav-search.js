document.addEventListener("DOMContentLoaded", () => {
  // Check if this page contains an items tree in <nav>.
  if(document.querySelector("nav .current-version details") === null) {
    return;
  }

  // Don't add the input in the version-front page.
  if(document.querySelector("main.version-front") !== null) {
    return;
  }

  // Add an icon for the search input.
  let search = document.createElement("INPUT");
  search.placeholder = "Search";
  search.accessKey = "s";
  search.classList.add("search");

  // Update visible items when the input is modified.
  window.navSearchInput = new NavSearchInput(search);

  let labelHeader = document.querySelector(".current-version > b");
  labelHeader.parentNode.insertBefore(search, labelHeader);
});

class NavSearchInput {
  constructor(elem) {
    this.nodesState = null;

    elem.addEventListener("input", () => {
      this.update(elem.value.trim());
    });

    elem.addEventListener("keydown", (event) => {
      this.onKeyDown(event);
    });


    // Focus the search input on "/".
    document.body.addEventListener("keydown", (event) => {
      if(event.target.tagName !== "INPUT" && event.key === "/") {
        event.preventDefault();
        elem.focus();
      }
    });
  }

  update(query) {
    if(query === "") {
      if(this.nodesState !== null) {
        this.restoreNodesState();
      }

      return;
    }

    if(this.nodesState === null) {
      this.saveNodesState();
    }

    let words = query.split(/ +/);
    let visibleNodes = new WeakSet();

    // Hide links that does not contains the words in the input.
    for(const elem of document.querySelectorAll("nav details :is(a, b)")) {
      let link = elem.innerText;
      let visible = words.every(w => link.includes(w));
      elem.classList.toggle("hidden", !visible);

      if(visible) {
        let it = elem;
        while(true) {
          it = it.parentNode;
          if(it === null) {
            break
          } else if(it.tagName === "DETAILS") {
            visibleNodes.add(it);
          }
        }
      } else {
        elem.classList.remove("selected");
      }
    }

    // Show only <details> nodes with visible items.
    for(const elem of document.querySelectorAll("nav details")) {
      if(visibleNodes.has(elem)) {
        elem.classList.remove("hidden");
        elem.open = true;
      } else {
        elem.classList.add("hidden");
      }
    }
  }

  onKeyDown(event) {
    let direction;
    switch(event.key) {
      case "ArrowUp":
        this.moveSelection(-1);
        break;

      case "ArrowDown":
        this.moveSelection(1);
        break;

      case "Enter":
        let inNewWindow = event.getModifierState("Control");
        this.openSelection(inNewWindow);
        break;

      default:
        return;
    }

    event.preventDefault();
  }

  moveSelection(direction) {
    let elems = document.querySelectorAll("nav details a:not(.hidden)")

    if(elems.length === 0) { return; }

    let foundIndex = -1;
    for(let index = 0; index < elems.length; index++) {
      if(elems[index].classList.contains("selected")) {
        elems[index].classList.remove("selected");
        foundIndex = index;
        break;
      }
    }

    foundIndex = foundIndex + direction;
    if(foundIndex < 0) {
      foundIndex = elems.length - 1;
    } else if(foundIndex >= elems.length) {
      foundIndex = 0;
    }

    elems[foundIndex].classList.add("selected");
  }

  openSelection(inNewWindow) {
    let elem = document.querySelector("nav a.selected");
    if(elem === null) { return; }

    if(inNewWindow) {
      window.open(elem.href, "_blank");
    } else {
      location.href = elem.href;
    }
  }

  saveNodesState() {
    let map = new WeakMap();

    for(const elem of document.querySelectorAll("nav details")) {
      map.set(elem, elem.open);
    }

    this.nodesState = map;
  }

  restoreNodesState() {
    if(this.nodesState === null) {
      return;
    }

    let map = this.nodesState;
    for(const elem of document.querySelectorAll("nav details")) {
      elem.open = map.get(elem);
    }

    for(const elem of document.querySelectorAll("nav .hidden")) {
      elem.classList.remove("hidden");
    }

    for(const elem of document.querySelectorAll("nav .selected")) {
      elem.classList.remove("selected");
    }

    this.nodesState = null;
  }

}
