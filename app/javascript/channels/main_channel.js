import consumer from "./consumer"

let myID = null;
let waitingForReplyTimeout = 0;
let globalMessage = null;
let globalInvitationMessage = null;
const handlers = {};
consumer.subscriptions.create("MainChannel", {
  async connected() {
    console.log(`QQQ: connected!`);
    if (location.pathname == '/') {
      // TODO: We really need to figure this out...
      $.get('/waiting_users', (data, status) => {
        console.log(`QQQ: update /waiting_users, data: ${ data }, status: ${ status }`);
      });
    }
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    console.log(`QQQ: disconnected!`);
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    try {
      return this.received_aux(data);
    } catch(ex) {
      console.error(`Error ${ ex } processing received data`);
      console.error(ex);
    }
  },
  received_aux(data) {
    // Called when there's incoming data on the websocket for this channel
    globalMessage = data.message;
    console.log(`QQQ: received msg ${ data.type }`, globalMessage);
    if (data.chatroom === 'main' && data.type === 'waitingUsers' && globalMessage) {
      repopulateWaitingList(globalMessage);
    } else if (data.type === 'invitation') {
      // console.log(`QQQ: got an invitation, my ID is ${ myID }`);
      // console.log(`QQQ: received message ${ JSON.stringify(data) }`);
      globalInvitationMessage = globalMessage;
      processInvitation(globalInvitationMessage);
    } else if (data.type === 'invitationCancelled') {
      // console.log(`QQQ: got an invitation-cancelled, my ID is ${ myID }`);
      // console.log(`QQQ: received message ${ JSON.stringify(data) }`);
      if (myID == globalMessage.to) {
        processInvitationCancellation(globalMessage);
      } else {
        console.log(`QQQ: I'm ${ myID }, ignoring a message for ${ globalMessage.to }`)
      }
    } else if (data.type === 'invitationEnding') {
      // console.log(`QQQ: got an invitation-ending, my ID is ${ myID }`);
      // console.log(`QQQ: received message ${ JSON.stringify(data) }`);
      processInvitationEnding(globalMessage);
    } else if (data.type === 'invitationAccepted') {
      // console.log(`QQQ: got an invitationAccepted for ${data.message.to}, my ID is ${myID}`);
      // console.log(`QQQ: received message ${JSON.stringify(data)}`);
      processInvitationAccepted(data.message);
    } else if (data.type === 'reloadGame') {
      console.log(`QQQ: got a reloadGame for ${data.message.to}, my ID is ${myID}`);
      console.log(`QQQ: received message ${JSON.stringify(data)}`);
      if (data.message.to != myID) {
        return;
      }
      processReloadGame(data.message);
    } else {
      console.log(`QQQ: received unexpected message ${ JSON.stringify(data) }`);
      console.table(data);
    }
  }
});

function processReloadGame(message) {
  if (!('game_id' in message)) {
    console.log(`!!! processReloadGame: Bad message: ${ JSON.stringify(message) }`);
    return;
  }
  window.location = `/games/${ message.game_id }`;
}

function processInvitationAccepted(data) {
  console.table(data);
  if (data.to == myID) {
    //TODO: Disconnect from this channel
    window.location.href = `/games/${ data.game_id }`;
  }
}

function processInvitationEnding(message) {
  if (message.from != myID) {
    return;
  }
  clearTimeout(waitingForReplyTimeout);
  const modal = $('#waiting-for-reply');
  modal.modal('toggle');
}

function updateMyAddRemoveLabel(status) {
  const button = document.querySelector('div#add-remove-waitlist.row input[type="submit"]');
  if (!button) {
    console.log(`QQQ: couldn't find the submit button`);
    return;
  }
  button.value = (status ? "Remove me from" : "Add me to") + " the waiting list.";
}

function repopulateWaitingList(users) {
  if (!myID) {
    console.log(`Can't repopulate: don't know my ID`)
    return;
  }
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
      if (user.id == myID) {
        foundMe = true;
        const span = document.createElement('span');
        span.textContent = user.username;
        li.appendChild(span);
      } else {
        const div = document.createElement('div');
        div.classList.add("btn-group");
        /*
        invitations_path(from: user.id, to: u.id), method: :post, :remote => true %></li>
         */
        div.innerHTML = `
          <button type="button btn btn-secondary" class="btn btn-default dropdown-toggle" data-toggle="dropdown"
                  aria-haspopup="true" aria-expanded="false">
            ${user.username}<span class="caret"></span>
          </button>
          <ul class="dropdown-menu need-a-boost">
            <li class="needy-dropdown-menuitem"><a data-remote="true" rel="nofollow" data-method="post" href="/invitations?from=${ myID }&amp;to=${ user.id }">Start a Game</a></li>
          </ul>
        `;
        li.appendChild(div);
        setImmediate(() => {
          document.querySelector('button.dropdown-toggle')
            .addEventListener('click', (event) => {
              const li = event.target.parentElement.querySelector('li.needy-dropdown-menuitem');
              if (!li) {
                console.log('No list item?');
                return;
              }
              setImmediate(() => {
                li.scrollIntoView();
              });
            });
        });
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
    // console.log(`QQQ: Looking at my invitation from ${message.from}`);
    handlers.setGotAnInvitationHandlers();
    return processInvitationForRecipient(message);
  } else {
    console.log(`QQQ: Ignore the invitation, I'm # ${ myID }`, message);
  }
}

function processInvitationForRecipient(message) {
  console.log(`QQQ: Looking at my invitation from ${ message.from }`, message);
  try {
    const modal = $('#got-an-invitation');
    if (!modal) {
      console.log(`Awp: Can't find modal #got-an-invitation`);
      return;
    }
    document.querySelector('#got-an-invitation #got-an-invitation-sender').textContent = message.fromUsername;
    modal.modal();
    // console.log(`QQQ: should see the modal now`);
  } catch(e) {
    console.error(`Failed to show the modal: ${ e }`);
  }
}

function processInvitationForSender(message) {
  console.log(`QQQ: Looking at my invitation to ${ message.to }`);
  try {
    const modal = $('#waiting-for-reply');
    if (!modal) {
      console.log(`Awp: Can't find modal #waiting-for-repl`);
      return;
    }
    handlers.setWaitingForReplyHandlers();
    document.querySelector('#waiting-for-reply #waiting-for-reply-target').textContent = message.toUsername;
    modal.modal();
    console.log(`QQQ: should see the modal now`);
    waitingForReplyTimeout = setTimeout(() => {
      fetch(`/invitations/${ message.id }?from=${ myID }&flash=timed%20out`, { mode: 'cors', cache: 'no-cache',
          credentials: "same-origin", // include, *same-origin, omit
          method: 'DELETE' });
      modal.modal('toggle');
      const timeoutModal = $('#waiting-for-reply-timeout');
      if (timeoutModal) {
        timeoutModal.modal();
        setTimeout(() => timeoutModal.modal('toggle'), 2_000);
      }
    }, 120 * 1000);
  } catch(e) {
    console.error(`Failed to show the modal: ${ e }`);
  }
}

function processInvitationCancellation(message) {
  try {
    $('#got-an-invitation').hide();
  } catch(ex) {
    console.log(`Error trying to hide a modal: ${ ex }`);
  }
  setImmediate(() => {
    console.log(`${ message.fromUsername } is no longer waiting: ${ message.message }`);
  });
  // For some reason we need to reload with the modal hidden.
  window.location.reload();
  // document.querySelector('#got-an-invitation #got-an-invitation-sender').textContent = `${ message.fromUsername } is no longer waiting: ${ message.message }`;
}

$(document).ready(async () => {
  try {
    $.get('/who_am_i', (data, status) => {
      console.log(`QQQ: /who_am_i => data: ${ data }, status: ${ status }`);
      if (status !== 'success') {
        console.log(`/who_am_i => status ${ status }`);
        alert("Sorry, problem with the server getting your user ID. Please try later.")
        return;
      }
      myID = data.id;
    });
  } catch(e) {
    console.log(`Failed to get my userID: ${ e }`);
  }
  handlers.setWaitingForReplyHandlers = () => {
    $("#waiting-for-reply-cancel").click(async () => {
      // console.log(`QQQ: Sender clicked cancel, globalMessage: #{ globalMessage }`);
      fetch(`/invitations/${globalMessage.id}?from=${myID}&flash=cancelled`, {
        mode: 'cors', cache: 'no-cache',
        credentials: "same-origin", // include, *same-origin, omit
        method: 'DELETE'
      });
      clearTimeout(waitingForReplyTimeout);
      waitingForReplyTimeout = 0;
    });
  };

  handlers.setGotAnInvitationHandlers = () => {
    $("#got-an-invitation-ok").click(async () => {
      // Chrome clears the console on location.href change, so don't write too much there at this point
      // console.log(`QQQ: Handling got-an-invitation-ok: Recipient clicked OK!`);
      // console.log(`QQQ: global-message: `, globalInvitationMessage)
      $.post('/games.json', {playerA: globalInvitationMessage['to'], playerB: globalInvitationMessage['from']})
        .done((data) => {
          // console.log(`QQQ: post games => ${data}`, data);
          console.table(data);
          // alert(`QQQ: post games => ${ JSON.stringify(data) }`);
          const url = `/invitations/${globalInvitationMessage.id}?originator=${globalInvitationMessage['from']}&reason=accepted&game_id=${data.location.id}`;
          // alert(`QQQ: post games => game_id=${ data.location.id }, url: ${ url }`);
          $.ajax({
            url,
            type: 'DELETE',
            success: (result) => {
              // console.log(`QQQ: delete worked? ${ result }`);
            }
          });
          // console.log(`QQQ: - setting location.href...`);
          window.location.href = `/games/${data.location.id}`;
          // console.log(`QQQ: + setting location.href...`);
        });
    });

    $("#got-an-invitation-cancel").click(async () => {
      // console.log(`QQQ: Recipient clicked Cancel!`);
      fetch(`/invitations/${globalMessage.id}?originator=${myID}&reason=declined`, {
        mode: 'cors', cache: 'no-cache',
        credentials: "same-origin", // include, *same-origin, omit
        method: 'PATCH'
      });
    });
  };
});
