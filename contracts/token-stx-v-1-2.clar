;; token implementation

;; Import the SIP-010 trait first
(use-trait sip-010-trait .sip-010-trait-ft-standard-v-1-1.sip-010-trait)

;; Then implement it
(impl-trait .sip-010-trait-ft-standard-v-1-1.sip-010-trait)

;; Define the fungible token
(define-fungible-token stacks-token)

;; SIP-010 Standard Error Codes
(define-constant ERR_NOT_ENOUGH_BALANCE (err u1))
(define-constant ERR_SAME_SENDER_RECIPIENT (err u2))
(define-constant ERR_NON_POSITIVE_AMOUNT (err u3))
(define-constant ERR_UNAUTHORIZED_SENDER (err u4))

;; Custom Error Constants
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_TOKEN_URI (err u101))

;; Token metadata
(define-data-var token-name (string-ascii 32) "Stacks Token")
(define-data-var token-symbol (string-ascii 32) "STKT")
(define-data-var token-decimals uint u6)
(define-data-var token-uri (optional (string-utf8 256)) none)

;; Contract owner and minting control
(define-data-var contract-owner principal tx-sender)
(define-data-var minting-enabled bool true)

;; ============ SIP-010 REQUIRED FUNCTIONS ============

;; SIP-010: Get token name
(define-read-only (get-name)
    (ok (var-get token-name))
)

;; SIP-010: Get token symbol  
(define-read-only (get-symbol)
    (ok (var-get token-symbol))
)

;; SIP-010: Get token decimals
(define-read-only (get-decimals)
    (ok (var-get token-decimals))
)

;; SIP-010: Get total token supply
(define-read-only (get-total-supply)
    (ok (ft-get-supply stacks-token))
)

;; SIP-010: Get token balance for an address
(define-read-only (get-balance (address principal))
    (ok (ft-get-balance stacks-token address))
)

;; SIP-010: Get token URI (optional)
(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

;; SIP-010: Transfer function with all required validations
(define-public (transfer 
    (amount uint)
    (sender principal) 
    (recipient principal)
    (memo (optional (buff 34)))
    )
    (begin
        ;; Validate amount is positive (SIP-010 u3)
        (asserts! (> amount u0) ERR_NON_POSITIVE_AMOUNT)
        
        ;; Validate sender has sufficient balance (SIP-010 u1)
        (asserts! (>= (ft-get-balance stacks-token sender) amount) 
            ERR_NOT_ENOUGH_BALANCE)
        
        ;; Validate sender and recipient are different (SIP-010 u2)
        (asserts! (not (is-eq sender recipient)) 
            ERR_SAME_SENDER_RECIPIENT)
        
        ;; Validate authorization - sender must be tx-sender (SIP-010 u4)
        (asserts! (is-eq tx-sender sender) 
            ERR_UNAUTHORIZED_SENDER)
        
        ;; Perform the token transfer
        (try! (ft-transfer? stacks-token amount sender recipient))
        
        ;; Emit memo if provided (SIP-010 requirement)
        (match memo memo-data 
            (print memo-data) 
            0x
        )
        
        ;; Print transfer event
        (print {
            action: "transfer",
            sender: sender,
            recipient: recipient, 
            amount: amount,
            memo: memo
        })
        
        (ok true)
    )
)

;; ============ ADDITIONAL MANAGEMENT FUNCTIONS ============

;; Mint new tokens (not in SIP-010 but commonly needed)
(define-public (mint 
    (amount uint)
    (recipient principal)
    )
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Only contract owner can mint
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        
        ;; Minting must be enabled
        (asserts! (var-get minting-enabled) ERR_NOT_AUTHORIZED)
        
        ;; Amount must be positive
        (asserts! (> amount u0) ERR_NON_POSITIVE_AMOUNT)
        
        ;; Mint the tokens
        (try! (ft-mint? stacks-token amount recipient))
        
        (print {
            action: "mint",
            caller: caller,
            recipient: recipient,
            amount: amount
        })
        
        (ok true)
    )
    )
)

;; Burn tokens (not in SIP-010 but commonly needed)
(define-public (burn (amount uint))
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Amount must be positive
        (asserts! (> amount u0) ERR_NON_POSITIVE_AMOUNT)
        
        ;; Caller must have sufficient balance
        (asserts! (>= (ft-get-balance stacks-token caller) amount) 
            ERR_NOT_ENOUGH_BALANCE)
        
        ;; Burn the tokens
        (try! (ft-burn? stacks-token amount caller))
        
        (print {
            action: "burn",
            caller: caller,
            amount: amount
        })
        
        (ok true)
    )
    )
)

;; ============ CONTRACT MANAGEMENT FUNCTIONS ============

;; Set token URI
(define-public (set-token-uri (uri (string-utf8 256)))
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Only contract owner can update URI
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        
        ;; URI must not be empty
        (asserts! (> (len uri) u0) ERR_INVALID_TOKEN_URI)
        
        ;; Update token URI
        (var-set token-uri (some uri))
        
        (print {
            action: "set-token-uri",
            caller: caller,
            uri: uri
        })
        
        (ok true)
    )
    )
)

;; Set token name
(define-public (set-token-name (name (string-ascii 32)))
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Only contract owner can update name
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        
        ;; Name must not be empty
        (asserts! (> (len name) u0) ERR_NOT_AUTHORIZED)
        
        (var-set token-name name)
        
        (print {
            action: "set-token-name", 
            caller: caller,
            name: name
        })
        
        (ok true)
    )
    )
)

;; Set token symbol
(define-public (set-token-symbol (symbol (string-ascii 32)))
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Only contract owner can update symbol
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        
        ;; Symbol must not be empty  
        (asserts! (> (len symbol) u0) ERR_NOT_AUTHORIZED)
        
        (var-set token-symbol symbol)
        
        (print {
            action: "set-token-symbol",
            caller: caller,
            symbol: symbol
        })
        
        (ok true)
    )
    )
)

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Only current owner can transfer ownership
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        
        ;; New owner must be a standard principal
        (asserts! (is-standard new-owner) ERR_NOT_AUTHORIZED)
        
        (var-set contract-owner new-owner)
        
        (print {
            action: "set-contract-owner",
            caller: caller,
            new-owner: new-owner
        })
        
        (ok true)
    )
    )
)

;; Enable/disable minting
(define-public (set-minting-enabled (enabled bool))
    (let (
        (caller tx-sender)
    )
    (begin
        ;; Only contract owner can control minting
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        
        (var-set minting-enabled enabled)
        
        (print {
            action: "set-minting-enabled",
            caller: caller, 
            enabled: enabled
        })
        
        (ok true)
    )
    )
)

;; Get current contract owner
(define-read-only (get-contract-owner)
    (ok (var-get contract-owner))
)

;; Get minting status
(define-read-only (get-minting-enabled)
    (ok (var-get minting-enabled))
)

(define-data-var paused bool false)

(define-public (set-paused (pause bool))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        (var-set paused pause)
        
        (print {
            event: "contract_paused",
            paused: pause,
            caller: tx-sender
        })
        
        (ok true)
    )
)

;; Add to transfer function:
;; (asserts! (not (var-get paused)) (err u5)) ;; ERR_CONTRACT_PAUSED
