import consumer from "./consumer"

let myID = null;
let waitingForReplyTimeout = 0;
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
      if (user.id == userID) {
        foundMe = true;
        const span = document.createElement('span');
        span.textContent = user.username;
        li.appendChild(span);
      } else {
        const div = document.createElement('div');
        div.classList.add("btn-group");
        div.innerHTML = `
          <button type="button btn btn-secondary" class="btn btn-default dropdown-toggle" data-toggle="dropdown"
                  aria-haspopup="true" aria-expanded="false">
            ${user.username}<span class="caret"></span>
          </button>
          <ul class="dropdown-menu">
            <li><a href="#">Start a Game</a></li>
          </ul>
        `;
        li.appendChild(div);
      }

      waitingList.appendChild(li);
    }
    updateMyAddRemoveLabel(foundMe);
  } catch(e) {
    console.log(`QQQ: error: ${ e }`);
    console.error(e);
  }
}

function processInvitation(message) {
  if (message.from == myID) {
    return processInvitationForSender(message);
  } else if (message.to == myID) {
    console.log(`QQQ: Looking at my invitation from ${message.from}`);
    return processInvitationForRecipient(message);
  } else {
    console.log(`QQQ: Ignore the invitation`, message);
  }
}

function processInvitationForRecipient(message) {
  console.log(`QQQ: Looking at my invitation from ${ message.from }`);
}

function processInvitationForSender(message) {
  console.log(`QQQ: Looking at my invitation to ${ message.to }`);
  try {
    const modal = $('#waiting-for-reply');
    if (!modal) {
      console.log(`Awp: Can't find modal #waiting-for-repl`);
      return;
    }
    document.querySelector('#waiting-for-reply #waiting-for-reply-target').textContent = message.toUsername;
    modal.modal();
    console.log(`QQQ: should see the modal now`);
    waitingForReplyTimeout = setTimeout(() => {
      fetch(`/invitations/${ message.id }&flash=timed%20out`, { mode: 'cors', cache: 'no-cache',
          credentials: "same-origin", // include, *same-origin, omit
          method: 'DELETE' });
      modal.modal('toggle');
      const timeoutModal = $('#waiting-for-reply-timeout');
      if (timeoutModal) {
        timeoutModal.modal();
        setTimeout(() => timeoutModal.modal('toggle'), 2_000);
      }
    }, 10 * 1000);
  } catch(e) {
    console.error(`Failed to show the modal: ${ e }`);
  }
}
