import consumer from "./consumer"

consumer.subscriptions.create("MainChannel", {
  async connected() {
    console.log(`QQQ: connected!`);
    fetch('/waiting_users');
    console.log(`QQQ: fetch done`);
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    console.log(`QQQ: disconnected!`);
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    if (data.chatroom === 'main' && data.type === 'waitingUsers' && data.message) {
      repopulateWaitingList(data.message, data.userID);
    } else {
      console.log(`QQQ: received message ${ JSON.stringify(data) }`);
      console.table(data);
    }
  }
});

function updateMyAddRemoveLabel(status) {
  const button = document.querySelector('div#add-remove-waitlist.row input[type="submit"]');
  if (!button) {
    console.log(`QQQ: couldn't find the submit button`);
    return;
  }
  button.value = (status ? "Remove me from" : "Add me to") + " the waiting list.";
}

function repopulateWaitingList(users, userID) {
  try {
    let foundMe = false;
    const elts = document.getElementsByClassName('waitlist');
    if (elts.length === 0) {
      console.log(`QQQ: No waiting list here (#1), return`);
      return;
    }
    const waitingList = elts.item(0);
    let lc;
    if (!waitingList) {
      console.log(`QQQ: No waiting list here (#2), return`);
      return;
    }
    if (users.length === 0) {
      waitingList.classList.add("hidden");
      console.log(`QQQ: no users???`)
      return;
    }
    waitingList.classList.remove("hidden");
    while ((lc = waitingList.lastChild)) {
      waitingList.removeChild(lc);
    }
    for (const user of users) {
      const li = document.createElement('li');
      li.classList.add('list-group-item', 'li-small-image');
      li.setAttribute("id", user.id);
      li.setAttribute("email", user.email);
      let imgURL = user.image_url;
      if (imgURL) {
        const img = document.createElement('img');
        img.src = imgURL;
        img.alt = imgURL;
        img.height = img.width = 100;
        li.appendChild(img);
      } else {
        const span = document.createElement('span');
        span.textContent = ' ';
        li.appendChild(span);
      }
      const span = document.createElement('span');
      span.textContent = user.username;
      li.appendChild(span);

      if (user.id == userID) {
        foundMe = true;
      }

      waitingList.appendChild(li);
    }
    updateMyAddRemoveLabel(foundMe);
  } catch(e) {
    console.log(`QQQ: error: ${ e }`);
    console.error(e);
  }
}
