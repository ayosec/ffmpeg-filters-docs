class SearchInput {
  constructor(elem) {
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
    let elems = document.querySelectorAll(this.selectionItemsQuery())

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
    let elem = document.querySelector(this.selectedItemQuery());
    if(elem === null) { return; }

    if(inNewWindow) {
      window.open(elem.href, "_blank");
    } else {
      location.href = elem.href;
    }
  }

}
