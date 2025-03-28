;; Decentralized Disaster Relief Protocol
;; A transparent and fair disaster relief fund management system

;; NFT Trait Definition
(define-trait nft-relief-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response principal uint))
        (get-last-token-id () (response uint uint))
        (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
    )
)

;; Protocol Constants
(define-constant PROTOCOL-ADMIN tx-sender)
(define-constant MIN-DONATION-AMOUNT u100000)
(define-constant DONATION-VOTING-THRESHOLD u75)
(define-constant RELIEF-TOKEN-BASE-URI "ipfs://disaster-relief/metadata/")
(define-constant VICTIM-VERIFICATION-THRESHOLD u3)

;; Error Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INACTIVE-DISASTER (err u101))
(define-constant ERR-INSUFFICIENT-PROTOCOL-FUNDS (err u102))
(define-constant ERR-INVALID-DONATION-AMOUNT (err u103))
(define-constant ERR-PROPOSAL-ALREADY-EXECUTED (err u104))
(define-constant ERR-TRANSFER-FAILED (err u105))
(define-constant ERR-NOT-TOKEN-OWNER (err u106))
(define-constant ERR-TOKEN-NOT-FOUND (err u107))
(define-constant ERR-DONOR-ALREADY-REGISTERED (err u108))
(define-constant ERR-INVALID-VERIFICATION-PROOF (err u109))
(define-constant ERR-VICTIM-NOT-VERIFIED (err u110))

;; Protocol State Variables
(define-data-var protocol-total-funds uint u0)
(define-data-var current-disaster-identifier uint u0)
(define-data-var latest-token-identifier uint u0)
(define-data-var latest-victim-identifier uint u0)

;; Data Mapping Structures
(define-map protocol-donors 
    principal 
    {
        cumulative-donation: uint, 
        donor-voting-power: uint, 
        donation-nft-count: uint
    }
)

(define-map disaster-records 
    uint 
    {
        disaster-name: (string-ascii 64), 
        disaster-severity-level: uint, 
        required-relief-funds: uint, 
        allocated-relief-funds: uint, 
        is-disaster-active: bool
    }
)

(define-map relief-allocation-proposals
    uint 
    {
        proposal-description: (string-ascii 256),
        proposed-relief-amount: uint,
        proposal-vote-count: uint,
        is-proposal-executed: bool
    }
)

(define-map victim-registration-records
    uint
    {
        victim-wallet: principal,
        associated-disaster-id: uint,
        victim-location: (string-ascii 64),
        damage-assessment-level: uint,
        is-victim-verified: bool,
        verification-attempt-count: uint,
        encrypted-victim-data: (string-ascii 1024),
        verification-proof: (string-ascii 1024)
    }
)

(define-map victim-verification-tracking
    {victim-record-id: uint, verification-authority: principal}
    bool
)

(define-map authorized-verification-oracles
    principal
    bool
)

(define-map token-metadata-uris
    uint 
    (string-ascii 256)
)

(define-map token-ownership-records
    uint
    principal
)

;; Non-Fungible Token for Disaster Relief
(define-non-fungible-token disaster-relief-contribution-token uint)

;; Read-Only Information Retrieval Functions
(define-read-only (get-donor-contribution-details (donor principal))
    (default-to 
        {
            cumulative-donation: u0, 
            donor-voting-power: u0, 
            donation-nft-count: u0
        }
        (map-get? protocol-donors donor)
    )
)

(define-read-only (get-disaster-details (disaster-id uint))
    (map-get? disaster-records disaster-id)
)

(define-read-only (get-victim-registration-info (victim-id uint))
    (map-get? victim-registration-records victim-id)
)

(define-read-only (check-victim-verification-status (victim-id uint))
    (let ((victim-record (unwrap! (get-victim-registration-info victim-id) (ok false))))
        (ok (get is-victim-verified victim-record))
    )
)

(define-read-only (get-protocol-total-funds)
    (var-get protocol-total-funds)
)

(define-read-only (get-token-owner (token-id uint))
    (ok (map-get? token-ownership-records token-id))
)

(define-read-only (get-token-metadata-uri (token-id uint))
    (ok (map-get? token-metadata-uris token-id))
)

(define-read-only (get-latest-token-identifier)
    (ok (var-get latest-token-identifier))
)

;; Victim Registration Process
(define-public (register-disaster-victim 
    (disaster-id uint)
    (victim-location (string-ascii 64))
    (damage-level uint)
    (encrypted-personal-data (string-ascii 1024))
    (verification-proof (string-ascii 1024)))
    (let (
        (new-victim-id (+ (var-get latest-victim-identifier) u1))
        (disaster-record (unwrap! (get-disaster-details disaster-id) ERR-INACTIVE-DISASTER))
    )
        (if (get is-disaster-active disaster-record)
            (begin
                (var-set latest-victim-identifier new-victim-id)
                (map-set victim-registration-records new-victim-id
                    {
                        victim-wallet: tx-sender,
                        associated-disaster-id: disaster-id,
                        victim-location: victim-location,
                        damage-assessment-level: damage-level,
                        is-victim-verified: false,
                        verification-attempt-count: u0,
                        encrypted-victim-data: encrypted-personal-data,
                        verification-proof: verification-proof
                    }
                )
                (ok new-victim-id)
            )
            ERR-INACTIVE-DISASTER
        )
    )
)

;; Oracle Management Functions
(define-public (register-verification-oracle (oracle-wallet principal))
    (if (is-eq tx-sender PROTOCOL-ADMIN)
        (begin
            (map-set authorized-verification-oracles oracle-wallet true)
            (ok true)
        )
        ERR-UNAUTHORIZED-ACCESS
    )
)

(define-public (verify-disaster-victim (victim-id uint))
    (let (
        (victim-record (unwrap! (get-victim-registration-info victim-id) ERR-UNAUTHORIZED-ACCESS))
        (is-authorized-oracle (default-to false (map-get? authorized-verification-oracles tx-sender)))
        (has-previous-verification (default-to false (map-get? victim-verification-tracking {victim-record-id: victim-id, verification-authority: tx-sender})))
    )
        (if (and is-authorized-oracle (not has-previous-verification))
            (begin
                (map-set victim-verification-tracking 
                    {victim-record-id: victim-id, verification-authority: tx-sender} 
                    true
                )
                (map-set victim-registration-records victim-id
                    (merge victim-record 
                        {
                            verification-attempt-count: (+ (get verification-attempt-count victim-record) u1),
                            is-victim-verified: (>= (+ (get verification-attempt-count victim-record) u1) VICTIM-VERIFICATION-THRESHOLD)
                        }
                    )
                )
                (ok true)
            )
            ERR-UNAUTHORIZED-ACCESS
        )
    )
)

;; Donation Management Function
(define-public (contribute-to-relief-fund)
    (let (
        (donation-amount (stx-get-balance tx-sender))
        (donor-details (get-donor-contribution-details tx-sender))
    )
        (if (>= donation-amount MIN-DONATION-AMOUNT)
            (begin
                (try! (stx-transfer? donation-amount tx-sender (as-contract tx-sender)))
                (map-set protocol-donors tx-sender
                    {
                        cumulative-donation: (+ (get cumulative-donation donor-details) donation-amount),
                        donor-voting-power: (+ (get donor-voting-power donor-details) donation-amount),
                        donation-nft-count: (+ (get donation-nft-count donor-details) u1)
                    }
                )
                (var-set protocol-total-funds (+ (var-get protocol-total-funds) donation-amount))
                (let ((new-token-id (+ (var-get latest-token-identifier) u1)))
                    (var-set latest-token-identifier new-token-id)
                    (try! (nft-mint? disaster-relief-contribution-token new-token-id tx-sender))
                    (map-set token-ownership-records new-token-id tx-sender)
                    (map-set token-metadata-uris new-token-id RELIEF-TOKEN-BASE-URI)
                    (ok true)
                )
            )
            ERR-INVALID-DONATION-AMOUNT
        )
    )
)

;; Disaster Registration Function
(define-public (register-new-disaster 
    (disaster-name (string-ascii 64)) 
    (disaster-severity uint) 
    (required-relief-funds uint))
    (let ((new-disaster-id (+ (var-get current-disaster-identifier) u1)))
        (if (is-eq tx-sender PROTOCOL-ADMIN)
            (begin
                (map-set disaster-records new-disaster-id
                    {
                        disaster-name: disaster-name,
                        disaster-severity-level: disaster-severity,
                        required-relief-funds: required-relief-funds,
                        allocated-relief-funds: u0,
                        is-disaster-active: true
                    }
                )
                (var-set current-disaster-identifier new-disaster-id)
                (ok new-disaster-id)
            )
            ERR-UNAUTHORIZED-ACCESS
        )
    )
)

;; Relief Proposal Creation Function
(define-public (create-relief-allocation-proposal 
    (disaster-id uint) 
    (proposal-description (string-ascii 256)) 
    (proposed-relief-amount uint))
    (let ((disaster-record (unwrap! (get-disaster-details disaster-id) ERR-INACTIVE-DISASTER)))
        (if (and 
                (get is-disaster-active disaster-record)
                (<= proposed-relief-amount (var-get protocol-total-funds)))
            (begin
                (map-set relief-allocation-proposals disaster-id
                    {
                        proposal-description: proposal-description,
                        proposed-relief-amount: proposed-relief-amount,
                        proposal-vote-count: u0,
                        is-proposal-executed: false
                    }
                )
                (ok true)
            )
            ERR-INSUFFICIENT-PROTOCOL-FUNDS)
    )
)

;; Proposal Voting Function
(define-public (vote-on-relief-proposal (disaster-id uint))
    (let (
        (proposal-record (unwrap! (map-get? relief-allocation-proposals disaster-id) ERR-INACTIVE-DISASTER))
        (donor-details (get-donor-contribution-details tx-sender))
    )
        (if (not (get is-proposal-executed proposal-record))
            (begin
                (map-set relief-allocation-proposals disaster-id
                    (merge proposal-record 
                        {proposal-vote-count: (+ (get proposal-vote-count proposal-record) (get donor-voting-power donor-details))}
                    )
                )
                (ok true)
            )
            ERR-PROPOSAL-ALREADY-EXECUTED)
    )
)

;; Token Transfer Function
(define-public (transfer-contribution-token 
    (token-id uint) 
    (sender principal) 
    (recipient principal))
    (let ((current-token-owner (unwrap! (map-get? token-ownership-records token-id) ERR-TOKEN-NOT-FOUND)))
        (if (and
                (is-eq tx-sender sender)
                (is-eq current-token-owner sender))
            (begin
                (map-set token-ownership-records token-id recipient)
                (ok true)
            )
            ERR-NOT-TOKEN-OWNER)
    )
)

;; Disaster Severity Update Function
(define-public (update-disaster-severity-level 
    (disaster-id uint) 
    (new-severity-level uint))
    (let ((disaster-record (unwrap! (get-disaster-details disaster-id) ERR-INACTIVE-DISASTER)))
        (if (is-eq tx-sender PROTOCOL-ADMIN)
            (begin
                (map-set disaster-records disaster-id
                    (merge disaster-record {disaster-severity-level: new-severity-level})) 
                (ok true)
            )
            ERR-UNAUTHORIZED-ACCESS)
    )
)