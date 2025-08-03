;; Tattoo and Piercing Shop Regulation Contract
;; Ensures body art establishments follow health regulations

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-SHOP-NOT-FOUND (err u401))
(define-constant ERR-INSPECTOR-NOT-FOUND (err u402))
(define-constant ERR-INVALID-INPUT (err u403))
(define-constant ERR-ARTIST-NOT-FOUND (err u404))

;; Data Variables
(define-data-var next-shop-id uint u1)
(define-data-var next-inspection-id uint u1)

;; Data Maps
(define-map body-art-shops
  { shop-id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    address: (string-ascii 200),
    shop-type: (string-ascii 50),
    license-status: (string-ascii 20),
    health-permit: (string-ascii 20),
    compliance-level: (string-ascii 20),
    artist-count: uint,
    last-inspection: uint,
    created-at: uint
  }
)

(define-map body-art-inspectors
  { inspector: principal }
  {
    name: (string-ascii 100),
    certification-id: (string-ascii 50),
    active: bool,
    specializations: (list 3 (string-ascii 50))
  }
)

(define-map shop-inspections
  { inspection-id: uint }
  {
    shop-id: uint,
    inspector: principal,
    inspection-date: uint,
    sterilization-score: uint,
    sanitation-score: uint,
    equipment-condition: (string-ascii 20),
    artist-licensing: bool,
    infection-control: bool,
    waste-disposal: bool,
    record-keeping: bool,
    violations: (list 6 (string-ascii 200)),
    overall-score: uint,
    passed: bool,
    notes: (string-ascii 400)
  }
)

(define-map licensed-artists
  { shop-id: uint, artist: principal }
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    specialties: (list 5 (string-ascii 50)),
    license-expiry: uint,
    bloodborne-training: uint,
    active: bool
  }
)

(define-map equipment-records
  { shop-id: uint, equipment-id: (string-ascii 50) }
  {
    equipment-type: (string-ascii 50),
    last-sterilization: uint,
    sterilization-method: (string-ascii 50),
    condition: (string-ascii 20),
    maintenance-date: uint
  }
)

;; Public Functions

;; Register a new body art shop
(define-public (register-body-art-shop (name (string-ascii 100)) (address (string-ascii 200)) (shop-type (string-ascii 50)))
  (let ((shop-id (var-get next-shop-id)))
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len address) u0) ERR-INVALID-INPUT)
    (map-set body-art-shops
      { shop-id: shop-id }
      {
        name: name,
        owner: tx-sender,
        address: address,
        shop-type: shop-type,
        license-status: "PENDING",
        health-permit: "PENDING",
        compliance-level: "UNKNOWN",
        artist-count: u0,
        last-inspection: u0,
        created-at: block-height
      }
    )
    (var-set next-shop-id (+ shop-id u1))
    (ok shop-id)
  )
)

;; Add a certified body art inspector
(define-public (add-body-art-inspector (inspector principal) (name (string-ascii 100)) (certification-id (string-ascii 50)) (specializations (list 3 (string-ascii 50))))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (map-set body-art-inspectors
      { inspector: inspector }
      {
        name: name,
        certification-id: certification-id,
        active: true,
        specializations: specializations
      }
    )
    (ok true)
  )
)

;; Register a licensed artist
(define-public (register-artist
  (shop-id uint)
  (artist principal)
  (name (string-ascii 100))
  (license-number (string-ascii 50))
  (specialties (list 5 (string-ascii 50)))
  (license-expiry uint)
  (bloodborne-training uint)
)
  (let ((shop (unwrap! (map-get? body-art-shops { shop-id: shop-id }) ERR-SHOP-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner shop)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len license-number) u0) ERR-INVALID-INPUT)
    (asserts! (> license-expiry block-height) ERR-INVALID-INPUT)
    (map-set licensed-artists
      { shop-id: shop-id, artist: artist }
      {
        name: name,
        license-number: license-number,
        specialties: specialties,
        license-expiry: license-expiry,
        bloodborne-training: bloodborne-training,
        active: true
      }
    )
    ;; Update artist count
    (map-set body-art-shops
      { shop-id: shop-id }
      (merge shop { artist-count: (+ (get artist-count shop) u1) })
    )
    (ok true)
  )
)

;; Conduct shop inspection
(define-public (conduct-body-art-inspection
  (shop-id uint)
  (sterilization-score uint)
  (sanitation-score uint)
  (equipment-condition (string-ascii 20))
  (artist-licensing bool)
  (infection-control bool)
  (waste-disposal bool)
  (record-keeping bool)
  (violations (list 6 (string-ascii 200)))
  (notes (string-ascii 400))
)
  (let (
    (inspection-id (var-get next-inspection-id))
    (shop (unwrap! (map-get? body-art-shops { shop-id: shop-id }) ERR-SHOP-NOT-FOUND))
    (inspector-info (unwrap! (map-get? body-art-inspectors { inspector: tx-sender }) ERR-INSPECTOR-NOT-FOUND))
    (overall-score (calculate-body-art-score sterilization-score sanitation-score artist-licensing infection-control waste-disposal record-keeping))
    (inspection-passed (and (>= overall-score u80) (< (len violations) u3)))
    (compliance-level (determine-body-art-compliance overall-score (len violations)))
  )
    (asserts! (get active inspector-info) ERR-NOT-AUTHORIZED)
    (asserts! (<= sterilization-score u100) ERR-INVALID-INPUT)
    (asserts! (<= sanitation-score u100) ERR-INVALID-INPUT)

    (map-set shop-inspections
      { inspection-id: inspection-id }
      {
        shop-id: shop-id,
        inspector: tx-sender,
        inspection-date: block-height,
        sterilization-score: sterilization-score,
        sanitation-score: sanitation-score,
        equipment-condition: equipment-condition,
        artist-licensing: artist-licensing,
        infection-control: infection-control,
        waste-disposal: waste-disposal,
        record-keeping: record-keeping,
        violations: violations,
        overall-score: overall-score,
        passed: inspection-passed,
        notes: notes
      }
    )

    ;; Update shop compliance
    (map-set body-art-shops
      { shop-id: shop-id }
      (merge shop {
        compliance-level: compliance-level,
        last-inspection: block-height,
        license-status: (if inspection-passed "ACTIVE" "CONDITIONAL"),
        health-permit: (if inspection-passed "VALID" "SUSPENDED")
      })
    )

    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Record equipment sterilization
(define-public (record-sterilization (shop-id uint) (equipment-id (string-ascii 50)) (sterilization-method (string-ascii 50)))
  (let ((shop (unwrap! (map-get? body-art-shops { shop-id: shop-id }) ERR-SHOP-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner shop)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len equipment-id) u0) ERR-INVALID-INPUT)
    (map-set equipment-records
      { shop-id: shop-id, equipment-id: equipment-id }
      {
        equipment-type: "TATTOO_NEEDLE",
        last-sterilization: block-height,
        sterilization-method: sterilization-method,
        condition: "STERILE",
        maintenance-date: block-height
      }
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get shop details
(define-read-only (get-body-art-shop (shop-id uint))
  (map-get? body-art-shops { shop-id: shop-id })
)

;; Get inspection details
(define-read-only (get-body-art-inspection (inspection-id uint))
  (map-get? shop-inspections { inspection-id: inspection-id })
)

;; Get artist details
(define-read-only (get-licensed-artist (shop-id uint) (artist principal))
  (map-get? licensed-artists { shop-id: shop-id, artist: artist })
)

;; Get equipment record
(define-read-only (get-equipment-record (shop-id uint) (equipment-id (string-ascii 50)))
  (map-get? equipment-records { shop-id: shop-id, equipment-id: equipment-id })
)

;; Check if shop is compliant
(define-read-only (is-shop-compliant (shop-id uint))
  (match (map-get? body-art-shops { shop-id: shop-id })
    shop (is-eq (get compliance-level shop) "COMPLIANT")
    false
  )
)

;; Check if artist license is valid
(define-read-only (is-artist-license-valid (shop-id uint) (artist principal))
  (match (map-get? licensed-artists { shop-id: shop-id, artist: artist })
    artist-info (and (get active artist-info) (> (get license-expiry artist-info) block-height))
    false
  )
)

;; Private Functions

;; Calculate overall body art inspection score
(define-private (calculate-body-art-score (sterilization uint) (sanitation uint) (licensing bool) (infection-control bool) (waste-disposal bool) (record-keeping bool))
  (let (
    (base-score (/ (+ sterilization sanitation) u2))
    (compliance-bonus (+
      (if licensing u10 u0)
      (if infection-control u10 u0)
      (if waste-disposal u5 u0)
      (if record-keeping u5 u0)
    ))
  )
    (if (<= (+ base-score compliance-bonus) u100)
      (+ base-score compliance-bonus)
      u100
    )
  )
)

;; Determine body art compliance level
(define-private (determine-body-art-compliance (score uint) (violation-count uint))
  (if (and (>= score u95) (is-eq violation-count u0))
    "COMPLIANT"
    (if (and (>= score u80) (<= violation-count u2))
      "MINOR_VIOLATIONS"
      (if (>= score u60)
        "MAJOR_VIOLATIONS"
        "NON_COMPLIANT"
      )
    )
  )
)
