;; Digital Art Collective Contract
;; A network for artists to display portfolios, collaborate, and verify authenticity

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ARTIST-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-ENDORSED (err u102))
(define-constant ERR-INVALID-PRIVACY-LEVEL (err u103))
(define-constant ERR-CERTIFICATE-NOT-FOUND (err u104))

;; Privacy levels
(define-constant PRIVACY-PUBLIC u0)
(define-constant PRIVACY-COLLECTIVE-MEMBERS u1)
(define-constant PRIVACY-PRIVATE u2)

;; Data structures
(define-map artist-profiles
  principal
  {
    artist-name: (string-ascii 50),
    bio: (string-ascii 500),
    portfolio-url: (string-ascii 200),
    privacy-level: uint,
    registered-at: uint,
    is-verified: bool
  })

(define-map artwork-collections
  { artist: principal, collection-id: uint }
  {
    collection-name: (string-ascii 100),
    medium: (string-ascii 100),
    creation-date: uint,
    completion-date: (optional uint),
    description: (string-ascii 500),
    privacy-level: uint
  })

(define-map authenticity-certificates
  { artist: principal, certificate-id: uint }
  {
    artwork-title: (string-ascii 100),
    certifier: (string-ascii 100),
    issue-date: uint,
    expiry-date: (optional uint),
    verification-hash: (string-ascii 200),
    privacy-level: uint,
    is-verified: bool
  })

(define-map collaboration-history
  { collaborator: principal, collaboratee: principal, project: (string-ascii 50) }
  {
    review: (string-ascii 200),
    timestamp: uint,
    is-public: bool
  })

(define-map collective-connections
  { artist1: principal, artist2: principal }
  {
    status: (string-ascii 20), ;; "pending", "accepted", "blocked"
    initiated-by: principal,
    timestamp: uint
  })

;; Counters for unique IDs
(define-data-var collection-id-counter uint u0)
(define-data-var certificate-id-counter uint u0)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Artist profile management functions
(define-public (create-artist-profile (artist-name (string-ascii 50)) (bio (string-ascii 500)) (portfolio-url (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (ok (map-set artist-profiles tx-sender {
      artist-name: artist-name,
      bio: bio,
      portfolio-url: portfolio-url,
      privacy-level: privacy-level,
      registered-at: block-height,
      is-verified: false
    }))))

(define-public (update-artist-profile (artist-name (string-ascii 50)) (bio (string-ascii 500)) (portfolio-url (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (asserts! (is-some (map-get? artist-profiles tx-sender)) ERR-ARTIST-NOT-FOUND)
    (ok (map-set artist-profiles tx-sender {
      artist-name: artist-name,
      bio: bio,
      portfolio-url: portfolio-url,
      privacy-level: privacy-level,
      registered-at: (default-to block-height (get registered-at (map-get? artist-profiles tx-sender))),
      is-verified: (default-to false (get is-verified (map-get? artist-profiles tx-sender)))
    }))))

;; Artwork collection functions
(define-public (add-artwork-collection (collection-name (string-ascii 100)) (medium (string-ascii 100)) (creation-date uint) (completion-date (optional uint)) (description (string-ascii 500)) (privacy-level uint))
  (let ((collection-id (+ (var-get collection-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? artist-profiles tx-sender)) ERR-ARTIST-NOT-FOUND)
      (var-set collection-id-counter collection-id)
      (ok (map-set artwork-collections { artist: tx-sender, collection-id: collection-id } {
        collection-name: collection-name,
        medium: medium,
        creation-date: creation-date,
        completion-date: completion-date,
        description: description,
        privacy-level: privacy-level
      })))))

;; Authenticity certificate functions
(define-public (add-authenticity-certificate (artwork-title (string-ascii 100)) (certifier (string-ascii 100)) (issue-date uint) (expiry-date (optional uint)) (verification-hash (string-ascii 200)) (privacy-level uint))
  (let ((certificate-id (+ (var-get certificate-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? artist-profiles tx-sender)) ERR-ARTIST-NOT-FOUND)
      (var-set certificate-id-counter certificate-id)
      (ok (map-set authenticity-certificates { artist: tx-sender, certificate-id: certificate-id } {
        artwork-title: artwork-title,
        certifier: certifier,
        issue-date: issue-date,
        expiry-date: expiry-date,
        verification-hash: verification-hash,
        privacy-level: privacy-level,
        is-verified: false
      })))))

(define-public (verify-authenticity-certificate (artist principal) (certificate-id uint))
  (let ((certificate (map-get? authenticity-certificates { artist: artist, certificate-id: certificate-id })))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some certificate) ERR-CERTIFICATE-NOT-FOUND)
      (ok (map-set authenticity-certificates { artist: artist, certificate-id: certificate-id }
        (merge (unwrap-panic certificate) { is-verified: true }))))))

;; Collaboration functions
(define-public (endorse-collaboration (collaboratee principal) (project (string-ascii 50)) (review (string-ascii 200)) (is-public bool))
  (begin
    (asserts! (is-some (map-get? artist-profiles tx-sender)) ERR-ARTIST-NOT-FOUND)
    (asserts! (is-some (map-get? artist-profiles collaboratee)) ERR-ARTIST-NOT-FOUND)
    (asserts! (is-none (map-get? collaboration-history { collaborator: tx-sender, collaboratee: collaboratee, project: project })) ERR-ALREADY-ENDORSED)
    (ok (map-set collaboration-history { collaborator: tx-sender, collaboratee: collaboratee, project: project } {
      review: review,
      timestamp: block-height,
      is-public: is-public
    }))))

;; Collective connection functions
(define-public (send-collective-invitation (to-artist principal))
  (begin
    (asserts! (is-some (map-get? artist-profiles tx-sender)) ERR-ARTIST-NOT-FOUND)
    (asserts! (is-some (map-get? artist-profiles to-artist)) ERR-ARTIST-NOT-FOUND)
    (ok (map-set collective-connections { artist1: tx-sender, artist2: to-artist } {
      status: "pending",
      initiated-by: tx-sender,
      timestamp: block-height
    }))))

(define-public (accept-collective-invitation (from-artist principal))
  (let ((connection (map-get? collective-connections { artist1: from-artist, artist2: tx-sender })))
    (begin
      (asserts! (is-some connection) ERR-ARTIST-NOT-FOUND)
      (asserts! (is-eq (get status (unwrap-panic connection)) "pending") ERR-NOT-AUTHORIZED)
      (ok (map-set collective-connections { artist1: from-artist, artist2: tx-sender }
        (merge (unwrap-panic connection) { status: "accepted" }))))))

;; Read-only functions with privacy controls
(define-read-only (get-artist-profile (artist principal))
  (let ((profile (map-get? artist-profiles artist)))
    (if (is-some profile)
      (let ((profile-data (unwrap-panic profile)))
        (if (or (is-eq (get privacy-level profile-data) PRIVACY-PUBLIC)
                (is-eq artist tx-sender)
                (is-collective-connected artist tx-sender))
          profile
          none))
      none)))

(define-read-only (get-artwork-collection (artist principal) (collection-id uint))
  (let ((collection (map-get? artwork-collections { artist: artist, collection-id: collection-id })))
    (if (is-some collection)
      (let ((collection-data (unwrap-panic collection)))
        (if (can-view-art-data artist (get privacy-level collection-data))
          collection
          none))
      none)))

(define-read-only (get-authenticity-certificate (artist principal) (certificate-id uint))
  (let ((certificate (map-get? authenticity-certificates { artist: artist, certificate-id: certificate-id })))
    (if (is-some certificate)
      (let ((certificate-data (unwrap-panic certificate)))
        (if (can-view-art-data artist (get privacy-level certificate-data))
          certificate
          none))
      none)))

(define-read-only (get-collaboration-history (collaborator principal) (collaboratee principal) (project (string-ascii 50)))
  (let ((collaboration (map-get? collaboration-history { collaborator: collaborator, collaboratee: collaboratee, project: project })))
    (if (is-some collaboration)
      (let ((collaboration-data (unwrap-panic collaboration)))
        (if (or (get is-public collaboration-data)
                (is-eq collaboratee tx-sender)
                (is-collective-connected collaboratee tx-sender))
          collaboration
          none))
      none)))

;; Helper functions
(define-read-only (is-collective-connected (artist1 principal) (artist2 principal))
  (or (is-eq (get status (default-to { status: "none", initiated-by: artist1, timestamp: u0 } 
                          (map-get? collective-connections { artist1: artist1, artist2: artist2 }))) "accepted")
      (is-eq (get status (default-to { status: "none", initiated-by: artist2, timestamp: u0 } 
                          (map-get? collective-connections { artist1: artist2, artist2: artist1 }))) "accepted")))

(define-read-only (can-view-art-data (data-owner principal) (privacy-level uint))
  (or (is-eq privacy-level PRIVACY-PUBLIC)
      (is-eq data-owner tx-sender)
      (and (is-eq privacy-level PRIVACY-COLLECTIVE-MEMBERS) (is-collective-connected data-owner tx-sender))))

;; Admin functions
(define-public (verify-artist-profile (artist principal))
  (let ((profile (map-get? artist-profiles artist)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some profile) ERR-ARTIST-NOT-FOUND)
      (ok (map-set artist-profiles artist
        (merge (unwrap-panic profile) { is-verified: true }))))))

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))))