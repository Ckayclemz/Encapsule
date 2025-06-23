;; Encapsule Smart Contract
;; A blockchain solution for chronologically-secured, encrypted payload storage

;; Exception Definitions
(define-constant deployer-address tx-sender)
(define-constant exc-unauthorized (err u100))
(define-constant exc-duplicate-entry (err u101))
(define-constant exc-missing-record (err u102))
(define-constant exc-premature-access (err u103))
(define-constant exc-invalid-duration (err u104))
(define-constant exc-operation-failure (err u105)) ;; Changed from 1205 to u105

;; Repository for chronologically-locked payloads
(define-map temporal-repository
    { capsule-ref: uint }
    {
        originator: principal,
        encrypted-payload: (string-utf8 500),
        release-block: uint,
        retrieved: bool
    }
)

;; Sequential identifier tracker
(define-data-var sequence-counter uint u1)

;; Internal function for payload insertion
(define-private (archive-internally (ref-num uint) (payload (string-utf8 500)) (maturity-block uint))
    (begin
        (map-insert temporal-repository
            { capsule-ref: ref-num }
            {
                originator: tx-sender,
                encrypted-payload: payload,
                release-block: maturity-block,
                retrieved: false
            }
        )
        true
    )
)

;; External function for creating chronologically-secured capsules
(define-public (encrypt-capsule (payload (string-utf8 500)) (lockdown-duration uint))
    (let
        (
            (active-ref (var-get sequence-counter))
            (maturity-block (+ stacks-block-height lockdown-duration))
        )
        (asserts! (> lockdown-duration u0) exc-invalid-duration)
        (asserts! (archive-internally active-ref payload maturity-block) exc-operation-failure)
        (var-set sequence-counter (+ active-ref u1))
        (ok active-ref)
    )
)

;; Decrypt capsule when maturity-block reached and caller is originator
(define-public (decrypt-capsule (ref-num uint))
    (let
        (
            (entry (unwrap! (map-get? temporal-repository { capsule-ref: ref-num }) exc-missing-record))
            (active-block stacks-block-height)
        )
        (asserts! (>= active-block (get release-block entry)) exc-premature-access)
        (asserts! (is-eq (get originator entry) tx-sender) exc-unauthorized)
        (ok (get encrypted-payload entry))
    )
)

;; Examine capsule metadata (originator-only access)
(define-read-only (examine-metadata (ref-num uint))
    (let
        (
            (entry (unwrap! (map-get? temporal-repository { capsule-ref: ref-num }) exc-missing-record))
        )
        (asserts! (is-eq (get originator entry) tx-sender) exc-unauthorized)
        (ok {
            release-block: (get release-block entry),
            retrieved: (get retrieved entry)
        })
    )
)

;; Display total quantity of capsules generated
(define-read-only (enumerate-capsules)
    (ok (- (var-get sequence-counter) u1))
)