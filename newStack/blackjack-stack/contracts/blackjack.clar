;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Simple Blackjack Escrow Contract for Hackathon
;; Just handles staking and payouts - game logic stays in JavaScript
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; --- Constants & Errors ---
(define-constant STAKE_AMOUNT u1000000) ;; 1 STX in microSTX
(define-constant ERR_GAME_NOT_FOUND (err u101))
(define-constant ERR_NOT_INVITED (err u102))
(define-constant ERR_GAME_FULL (err u103))
(define-constant ERR_GAME_NOT_READY (err u104))
(define-constant ERR_UNAUTHORIZED (err u105))
(define-constant ERR_ALREADY_PAID (err u106))
(define-constant ERR_INVALID_WINNER (err u107))

;; --- Data Storage ---
(define-data-var game-id-counter uint u0)
(define-constant contract-owner tx-sender)

(define-map games uint {
  player1: principal,
  player2: principal,
  player1-staked: bool,
  player2-staked: bool,
  winner: (optional principal),
  prize-claimed: bool
})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC STAKING FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Player 1 creates a game lobby and stakes 1 STX
(define-public (create-game (opponent principal))
  (begin
    (try! (stx-transfer? STAKE_AMOUNT tx-sender (as-contract tx-sender)))
    (let ((game-id (+ (var-get game-id-counter) u1)))
      (var-set game-id-counter game-id)
      (map-set games game-id {
        player1: tx-sender,
        player2: opponent,
        player1-staked: true,
        player2-staked: false,
        winner: none,
        prize-claimed: false
      })
      (ok game-id)
    )
  )
)

;; Player 2 joins an existing game and stakes 1 STX
(define-public (join-game (game-id uint))
  (let ((game (unwrap! (map-get? games game-id) ERR_GAME_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get player2 game)) ERR_NOT_INVITED)
    (asserts! (not (get player2-staked game)) ERR_GAME_FULL)
    (try! (stx-transfer? STAKE_AMOUNT tx-sender (as-contract tx-sender)))
    (map-set games game-id (merge game { player2-staked: true }))
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PAYOUT FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Anyone can call this to pay the winner (after game ends in JS)
(define-public (payout-winner (game-id uint) (winner-principal principal))
  (let ((game (unwrap! (map-get? games game-id) ERR_GAME_NOT_FOUND)))
    ;; Security checks
    (asserts! (and (get player1-staked game) (get player2-staked game)) ERR_GAME_NOT_READY)
    (asserts! (not (get prize-claimed game)) ERR_ALREADY_PAID)
    (asserts! (or (is-eq winner-principal (get player1 game)) (is-eq winner-principal (get player2 game))) ERR_INVALID_WINNER)
    
    ;; Mark as paid and set winner
    (map-set games game-id (merge game { prize-claimed: true, winner: (some winner-principal) }))
    
    ;; Transfer 2 STX to winner
    (try! (as-contract (stx-transfer? (* STAKE_AMOUNT u2) tx-sender winner-principal)))
    (ok true)
  )
)

;; Refund both players in case of tie
(define-public (refund-tie (game-id uint))
  (let ((game (unwrap! (map-get? games game-id) ERR_GAME_NOT_FOUND)))
    (asserts! (and (get player1-staked game) (get player2-staked game)) ERR_GAME_NOT_READY)
    (asserts! (not (get prize-claimed game)) ERR_ALREADY_PAID)
    
    (map-set games game-id (merge game { prize-claimed: true }))
    
    ;; Refund 1 STX to each player
    (try! (as-contract (stx-transfer? STAKE_AMOUNT tx-sender (get player1 game))))
    (try! (as-contract (stx-transfer? STAKE_AMOUNT tx-sender (get player2 game))))
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-game-info (game-id uint))
  (map-get? games game-id)
)

(define-read-only (get-current-game-id)
  (var-get game-id-counter)
)