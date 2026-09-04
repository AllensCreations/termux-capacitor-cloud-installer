/**
 * Offline-First Mobile Application Logic
 */

document.addEventListener("DOMContentLoaded", () => {
  initNetworkStatus();
  initOfflineCounter();
});

// 1. Connection status monitor
function initNetworkStatus() {
  const statusEl = document.getElementById("connection-status");
  if (!statusEl) return;

  function update() {
    if (navigator.onLine) {
      statusEl.textContent = "● Online";
      statusEl.className = "status-pill status-online";
    } else {
      statusEl.textContent = "● Offline (Local Mode)";
      statusEl.className = "status-pill status-offline";
    }
  }

  window.addEventListener("online", update);
  window.addEventListener("offline", update);
  update();
}

// 2. Offline local storage state demo
function initOfflineCounter() {
  const display = document.getElementById("counter-value");
  const btnInc = document.getElementById("btn-increment");
  const btnDec = document.getElementById("btn-decrement");

  if (!display || !btnInc || !btnDec) return;

  let count = parseInt(localStorage.getItem("offline_counter") || "0", 10);
  display.textContent = count;

  btnInc.addEventListener("click", () => {
    count++;
    localStorage.setItem("offline_counter", count.toString());
    display.textContent = count;
  });

  btnDec.addEventListener("click", () => {
    count--;
    localStorage.setItem("offline_counter", count.toString());
    display.textContent = count;
  });
}
