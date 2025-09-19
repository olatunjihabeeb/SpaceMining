
;; title: SpaceMining
;; version: 1.0.0
;; summary: Synthetic assets smart contract for asteroid mining and space resource extraction exposure
;; description: This contract provides exposure to asteroid mining operations through synthetic assets,
;;              allowing users to stake STX and receive shares representing space mining operations.

;; traits
(define-trait sip-010-trait
  (
    ;; Transfer from the caller to a new principal
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))

    ;; the human readable name of the token
    (get-name () (response (string-ascii 32) uint))

    ;; the ticker symbol, or empty if none
    (get-symbol () (response (string-ascii 32) uint))

    ;; the number of decimals used, e.g. 6 would mean 1_000_000 represents 1 token
    (get-decimals () (response uint uint))

    ;; the balance of the passed principal
    (get-balance (principal) (response uint uint))

    ;; the current total supply (which does not need to be a constant)
    (get-total-supply () (response uint uint))

    ;; an optional URI that represents metadata of this token
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; token definitions
(define-fungible-token space-mining-token)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-mining-pool-not-found (err u103))
(define-constant err-insufficient-staking (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-not-found (err u106))

;; Mining resource types
(define-constant RESOURCE-PLATINUM u1)
(define-constant RESOURCE-GOLD u2)
(define-constant RESOURCE-RARE-EARTH u3)
(define-constant RESOURCE-WATER u4)

;; Token constants
(define-constant TOKEN-NAME "SpaceMining Token")
(define-constant TOKEN-SYMBOL "SMT")
(define-constant TOKEN-DECIMALS u6)
(define-constant TOKEN-URI u"https://spacemining.io/metadata.json")

;; data vars
(define-data-var total-mining-pools uint u0)
(define-data-var total-staked uint u0)
(define-data-var mining-active bool false)
(define-data-var reward-rate uint u100) ;; Base reward rate per block (0.01%)

;; data maps
;; Mining pools - each represents a different asteroid or mining operation
(define-map mining-pools
  { pool-id: uint }
  {
    name: (string-ascii 64),
    resource-type: uint,
    total-staked: uint,
    reward-multiplier: uint, ;; multiplier for rewards (100 = 1x, 200 = 2x, etc.)
    active: bool,
    created-at: uint
  }
)

;; User stakes in mining pools
(define-map user-stakes
  { user: principal, pool-id: uint }
  {
    amount: uint,
    staked-at: uint,
    last-claim: uint
  }
)

;; User total stake tracking
(define-map user-totals
  { user: principal }
  {
    total-staked: uint,
    total-rewards: uint
  }
)

;; Resource prices (synthetic prices for different space resources)
(define-map resource-prices
  { resource-type: uint }
  { price-per-unit: uint } ;; Price in micro-STX
)

;; public functions

;; SIP-010 Token Standard Implementation
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq tx-sender from) (is-eq contract-caller from)) err-owner-only)
    (ft-transfer? space-mining-token amount from to)
  )
)

(define-read-only (get-name)
  (ok TOKEN-NAME)
)

(define-read-only (get-symbol)
  (ok TOKEN-SYMBOL)
)

(define-read-only (get-decimals)
  (ok TOKEN-DECIMALS)
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance space-mining-token who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply space-mining-token))
)

(define-read-only (get-token-uri)
  (ok (some TOKEN-URI))
)

;; Mining Pool Management
(define-public (create-mining-pool (name (string-ascii 64)) (resource-type uint) (reward-multiplier uint))
  (let ((new-pool-id (+ (var-get total-mining-pools) u1)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (>= resource-type u1) (<= resource-type u4)) err-invalid-amount)
    (asserts! (> reward-multiplier u0) err-invalid-amount)

    (map-set mining-pools
      { pool-id: new-pool-id }
      {
        name: name,
        resource-type: resource-type,
        total-staked: u0,
        reward-multiplier: reward-multiplier,
        active: true,
        created-at: block-height
      }
    )
    (var-set total-mining-pools new-pool-id)
    (ok new-pool-id)
  )
)

;; Staking Functions
(define-public (stake-in-pool (pool-id uint) (amount uint))
  (let (
    (pool (unwrap! (map-get? mining-pools { pool-id: pool-id }) err-mining-pool-not-found))
    (current-stake (default-to { amount: u0, staked-at: u0, last-claim: u0 }
                               (map-get? user-stakes { user: tx-sender, pool-id: pool-id })))
    (user-total (default-to { total-staked: u0, total-rewards: u0 }
                            (map-get? user-totals { user: tx-sender })))
  )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (get active pool) err-mining-pool-not-found)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Update user stake
    (map-set user-stakes
      { user: tx-sender, pool-id: pool-id }
      {
        amount: (+ (get amount current-stake) amount),
        staked-at: block-height,
        last-claim: block-height
      }
    )

    ;; Update pool total
    (map-set mining-pools
      { pool-id: pool-id }
      (merge pool { total-staked: (+ (get total-staked pool) amount) })
    )

    ;; Update user total
    (map-set user-totals
      { user: tx-sender }
      (merge user-total { total-staked: (+ (get total-staked user-total) amount) })
    )

    ;; Update global total
    (var-set total-staked (+ (var-get total-staked) amount))

    ;; Mint synthetic mining tokens
    (try! (ft-mint? space-mining-token amount tx-sender))

    (ok amount)
  )
)

;; Claim mining rewards
(define-public (claim-rewards (pool-id uint))
  (let (
    (pool (unwrap! (map-get? mining-pools { pool-id: pool-id }) err-mining-pool-not-found))
    (user-stake (unwrap! (map-get? user-stakes { user: tx-sender, pool-id: pool-id }) err-not-found))
    (blocks-since-last-claim (- block-height (get last-claim user-stake)))
    (base-rewards (/ (* (get amount user-stake) (var-get reward-rate) blocks-since-last-claim) u10000))
    (multiplied-rewards (/ (* base-rewards (get reward-multiplier pool)) u100))
    (user-total (default-to { total-staked: u0, total-rewards: u0 }
                            (map-get? user-totals { user: tx-sender })))
  )
    (asserts! (get active pool) err-mining-pool-not-found)
    (asserts! (> blocks-since-last-claim u0) err-invalid-amount)

    ;; Update last claim block
    (map-set user-stakes
      { user: tx-sender, pool-id: pool-id }
      (merge user-stake { last-claim: block-height })
    )

    ;; Update user total rewards
    (map-set user-totals
      { user: tx-sender }
      (merge user-total { total-rewards: (+ (get total-rewards user-total) multiplied-rewards) })
    )

    ;; Transfer STX rewards from contract
    (try! (as-contract (stx-transfer? multiplied-rewards tx-sender tx-sender)))

    (ok multiplied-rewards)
  )
)

;; Unstake from pool
(define-public (unstake-from-pool (pool-id uint) (amount uint))
  (let (
    (pool (unwrap! (map-get? mining-pools { pool-id: pool-id }) err-mining-pool-not-found))
    (user-stake (unwrap! (map-get? user-stakes { user: tx-sender, pool-id: pool-id }) err-not-found))
    (user-total (default-to { total-staked: u0, total-rewards: u0 }
                            (map-get? user-totals { user: tx-sender })))
  )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= amount (get amount user-stake)) err-insufficient-balance)

    ;; Claim any pending rewards first
    (try! (claim-rewards pool-id))

    ;; Update user stake
    (if (is-eq amount (get amount user-stake))
      ;; Remove stake completely
      (map-delete user-stakes { user: tx-sender, pool-id: pool-id })
      ;; Update stake amount
      (map-set user-stakes
        { user: tx-sender, pool-id: pool-id }
        (merge user-stake { amount: (- (get amount user-stake) amount) })
      )
    )

    ;; Update pool total
    (map-set mining-pools
      { pool-id: pool-id }
      (merge pool { total-staked: (- (get total-staked pool) amount) })
    )

    ;; Update user total
    (map-set user-totals
      { user: tx-sender }
      (merge user-total { total-staked: (- (get total-staked user-total) amount) })
    )

    ;; Update global total
    (var-set total-staked (- (var-get total-staked) amount))

    ;; Burn synthetic mining tokens
    (try! (ft-burn? space-mining-token amount tx-sender))

    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))

    (ok amount)
  )
)

;; Admin functions
(define-public (set-mining-active (active bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set mining-active active)
    (ok active)
  )
)

(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u1000) err-invalid-amount) ;; Max 10% per block
    (var-set reward-rate new-rate)
    (ok new-rate)
  )
)

(define-public (update-resource-price (resource-type uint) (price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (>= resource-type u1) (<= resource-type u4)) err-invalid-amount)
    (map-set resource-prices { resource-type: resource-type } { price-per-unit: price })
    (ok price)
  )
)

(define-public (toggle-pool-status (pool-id uint))
  (let ((pool (unwrap! (map-get? mining-pools { pool-id: pool-id }) err-mining-pool-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set mining-pools
      { pool-id: pool-id }
      (merge pool { active: (not (get active pool)) })
    )
    (ok (not (get active pool)))
  )
)

;; read only functions
(define-read-only (get-mining-pool (pool-id uint))
  (map-get? mining-pools { pool-id: pool-id })
)

(define-read-only (get-user-stake (user principal) (pool-id uint))
  (map-get? user-stakes { user: user, pool-id: pool-id })
)

(define-read-only (get-user-totals (user principal))
  (map-get? user-totals { user: user })
)

(define-read-only (get-total-mining-pools)
  (var-get total-mining-pools)
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)

(define-read-only (get-mining-active)
  (var-get mining-active)
)

(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

(define-read-only (get-resource-price (resource-type uint))
  (map-get? resource-prices { resource-type: resource-type })
)

(define-read-only (calculate-pending-rewards (user principal) (pool-id uint))
  (match (map-get? mining-pools { pool-id: pool-id })
    pool (match (map-get? user-stakes { user: user, pool-id: pool-id })
      user-stake (let (
        (blocks-since-last-claim (- block-height (get last-claim user-stake)))
        (base-rewards (/ (* (get amount user-stake) (var-get reward-rate) blocks-since-last-claim) u10000))
        (multiplied-rewards (/ (* base-rewards (get reward-multiplier pool)) u100))
      )
        (ok multiplied-rewards)
      )
      err-not-found
    )
    err-mining-pool-not-found
  )
)

;; private functions
(define-private (is-valid-resource-type (resource-type uint))
  (and (>= resource-type u1) (<= resource-type u4))
)

;; Initialize default resource prices
(map-set resource-prices { resource-type: RESOURCE-PLATINUM } { price-per-unit: u1000000 })
(map-set resource-prices { resource-type: RESOURCE-GOLD } { price-per-unit: u800000 })
(map-set resource-prices { resource-type: RESOURCE-RARE-EARTH } { price-per-unit: u1500000 })
(map-set resource-prices { resource-type: RESOURCE-WATER } { price-per-unit: u100000 })
