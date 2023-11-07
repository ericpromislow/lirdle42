import consumer from "./consumer"

// this.App = {};
// App.cable = ActionCable.createConsumer();

consumer.subscriptions.create("MainChannel", {
  connected() {
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
    console.log(`QQQ: received message ${ JSON.stringify(data) }`);
    console.table(data);
    if (data.chatroom === 'main' && data.type === 'waitingUsers' && data.message) {
      repopulateWaitingList(data.message);
    }
  }
});

function repopulateWaitingList(users) {
  try {
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
      li.textContent = user.username;

      waitingList.appendChild(li);
    }
  } catch(e) {
    console.log(`QQQ: error: ${ e }`);
    console.error(e);
  }
}
