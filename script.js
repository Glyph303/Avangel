"use strict";

// -------------------- GAME STATE -------------------- //
const deckSize = 20;
let deck = []; // shuffled deck
let currentPlayer = 0; // 0 = player1, 1 = player2
let scores = [[], []]; // store drawn card values for each player
let hasStood = [false, false]; // track if players stood
let gameOver = false;

// DOM elements
const btnStartP0 = document.querySelector(".btn--player--0");
const btnStartP1 = document.querySelector(".btn--player--1");
const btnDeal = document.querySelector(".btn--deal");
const btnHit = document.querySelector(".btn--hit");
const btnStand = document.querySelector(".btn--stand");
const btnLimit = document.querySelector(".btn--limit");

const scoreEl0 = document.getElementById("current--0");
const scoreEl1 = document.getElementById("current--1");

// -------------------- HELPERS -------------------- //

// Build a mini deck of 20 cards with values between 1-11
function buildDeck() {
  const values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11]; // Blackjack values
  let d = [];
  while (d.length < deckSize) {
    const rand = values[Math.floor(Math.random() * values.length)];
    d.push(rand);
  }
  return shuffle(d);
}

// Fisher-Yates shuffle
function shuffle(array) {
  let m = array.length, t, i;
  while (m) {
    i = Math.floor(Math.random() * m--);
    t = array[m];
    array[m] = array[i];
    array[i] = t;
  }
  return array;
}

function showScores() {
  console.log(`Player 1: ${scores[0]} (Total: ${calcScore(scores[0])})`);
  console.log(`Player 2: ${scores[1]} (Total: ${calcScore(scores[1])})`);
}

// Calculate total score for a player
function calcScore(arr) {
  return arr.reduce((a, b) => a + b, 0);
}

// Update UI scores
function updateUI() {
  scoreEl0.textContent = calcScore(scores[0]);
  scoreEl1.textContent = calcScore(scores[1]);
  btnLimit.textContent = `Cards left: ${deck.length}`;
}

// Switch to next player
function switchPlayer() {
  currentPlayer = currentPlayer === 0 ? 1 : 0;
  if (hasStood[currentPlayer]) {
    if (hasStood.every(Boolean)) {
      endGame();
    }
    // Otherwise, skip to the other player again
    else {
      switchPlayer();
    }
  }
}

// End game: show results
function endGame() {
  gameOver = true;
  showScores();
  const total0 = calcScore(scores[0]);
  const total1 = calcScore(scores[1]);

  let result;
  if (total0 > 21 && total1 > 21) {
    result = "Both players busted! No winner.";
  } else if (total0 > 21) {
    result = "Player 2 wins (Player 1 busted)!";
  } else if (total1 > 21) {
    result = "Player 1 wins (Player 2 busted)!";
  } else if (total0 === total1) {
    result = "It's a tie!";
  } else if (total0 > total1) {
    result = "Player 1 wins!";
  } else {
    result = "Player 2 wins!";
  }

  console.log(`Game Over!\n\nPlayer 1: ${total0}\nPlayer 2: ${total1}\n\n${result}\n\n\n`);
}

// -------------------- GAME LOGIC -------------------- //


// Start game for either player
function startGame() {
  deck.length = 20;
  deck = buildDeck();
  scores = [[], []];
  hasStood = [false, false];
  currentPlayer = 0;
  gameOver = false;
  updateUI();
}

// Deal one card to current player
function hit() {
  if (gameOver || deck.length === 0) return;
  if(hasStood[currentPlayer]) return;
  const card = deck.pop();
  scores[currentPlayer].push(card);
  updateUI();
  

  if (hasStood.every(Boolean) || deck.length === 0) {
    endGame();
    return;
    }    
    switchPlayer();
}

// Player stands
function stand() {
  if (gameOver) return;
  hasStood[currentPlayer] = true;
  if (hasStood.every(Boolean) || deck.length === 0) {
    endGame();
    return;
  }
  switchPlayer();
}

// -------------------- EVENT LISTENERS -------------------- //
//btnStartP0.addEventListener("click", () => stake(0));
//btnStartP1.addEventListener("click", () => stake(1));
btnHit.addEventListener("click", hit);
btnStand.addEventListener("click", stand);
btnDeal.addEventListener("click", () => startGame());
btnLimit.addEventListener("click", updateUI);
