;; Childcare Facility Inspection Contract
;; Monitors daycare centers and preschools for safety and quality

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-FACILITY-NOT-FOUND (err u301))
(define-constant ERR-INSPECTOR-NOT-FOUND (err u302))
(define-constant ERR-INVALID-INPUT (err u303))
(define-constant ERR-RATIO-VIOLATION (err u304))

;; Data Variables
(define-data-var next-facility-id uint u1)
(define-data-var next-inspection-id uint u1)

;; Data Maps
(define-map childcare-facilities
  { facility-id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    address: (string-ascii 200),
    facility-type: (string-ascii 50),
    license-status: (string-ascii 20),
    capacity: uint,
    current-enrollment: uint,
    staff-count: uint,
    compliance-rating: (string-ascii 20),
    last-inspection: uint,
    created-at: uint
  }
)

(define-map childcare-inspectors
  { inspector: principal }
  {
    name: (string-ascii 100),
    certification-id: (string-ascii 50),
    active: bool,
    specializations: (list 4 (string-ascii 50))
  }
)

(define-map facility-inspections
  { inspection-id: uint }
  {
    facility-id: uint,
    inspector: principal,
    inspection-date: uint,
    inspection-type: (string-ascii 50),
    safety-score: uint,
    educational-score: uint,
    staff-qualifications: bool,
    background-checks-current: bool,
    ratio-compliant: bool,
    facility-condition: (string-ascii 20),
    violations: (list 8 (string-ascii 200)),
    overall-rating: (string-ascii 20),
    notes: (string-ascii 500)
  }
)

(define-map staff-records
  { facility-id: uint, staff-member: principal }
  {
    name: (string-ascii 100),
    position: (string-ascii 50),
    certification-date: uint,
    background-check-date: uint,
    training-hours: uint,
    active: bool
  }
)

;; Public Functions

;; Register a new childcare facility
(define-public (register-childcare-facility
  (name (string-ascii 100))
  (address (string-ascii 200))
  (facility-type (string-ascii 50))
  (capacity uint)
)
  (let ((facility-id (var-get next-facility-id)))
    (asserts! (not (<= (len name) u0)) ERR-INVALID-INPUT)
    (asserts! (not (<= (len address) u0)) ERR-INVALID-INPUT)
    (asserts! (not (<= capacity u0)) ERR-INVALID-INPUT)
    (map-set childcare-facilities
      { facility-id: facility-id }
      {
        name: name,
        owner: tx-sender,
        address: address,
        facility-type: facility-type,
        license-status: "PENDING",
        capacity: capacity,
        current-enrollment: u0,
        staff-count: u0,
        compliance-rating: "UNKNOWN",
        last-inspection: u0,
        created-at: block-height
      }
    )
    (var-set next-facility-id (+ facility-id u1))
    (ok facility-id)
  )
)

;; Add a certified childcare inspector
(define-public (add-childcare-inspector (inspector principal) (name (string-ascii 100)) (certification-id (string-ascii 50)) (specializations (list 4 (string-ascii 50))))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (<= (len name) u0)) ERR-INVALID-INPUT)
    (map-set childcare-inspectors
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

;; Add staff member to facility
(define-public (add-staff-member
  (facility-id uint)
  (staff-member principal)
  (name (string-ascii 100))
  (position (string-ascii 50))
  (certification-date uint)
  (background-check-date uint)
  (training-hours uint)
)
  (let ((facility (unwrap! (map-get? childcare-facilities { facility-id: facility-id }) ERR-FACILITY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner facility)) ERR-NOT-AUTHORIZED)
    (asserts! (not (<= (len name) u0)) ERR-INVALID-INPUT)
    (map-set staff-records
      { facility-id: facility-id, staff-member: staff-member }
      {
        name: name,
        position: position,
        certification-date: certification-date,
        background-check-date: background-check-date,
        training-hours: training-hours,
        active: true
      }
    )
    ;; Update staff count
    (map-set childcare-facilities
      { facility-id: facility-id }
      (merge facility { staff-count: (+ (get staff-count facility) u1) })
    )
    (ok true)
  )
)

;; Conduct facility inspection
(define-public (conduct-childcare-inspection
  (facility-id uint)
  (inspection-type (string-ascii 50))
  (safety-score uint)
  (educational-score uint)
  (staff-qualifications bool)
  (background-checks-current bool)
  (facility-condition (string-ascii 20))
  (violations (list 8 (string-ascii 200)))
  (notes (string-ascii 500))
)
  (let (
    (inspection-id (var-get next-inspection-id))
    (facility (unwrap! (map-get? childcare-facilities { facility-id: facility-id }) ERR-FACILITY-NOT-FOUND))
    (inspector-info (unwrap! (map-get? childcare-inspectors { inspector: tx-sender }) ERR-INSPECTOR-NOT-FOUND))
    (ratio-compliant (check-staff-child-ratio facility-id (get current-enrollment facility) (get staff-count facility)))
    (overall-rating (determine-childcare-rating safety-score educational-score staff-qualifications background-checks-current ratio-compliant (len violations)))
  )
    (asserts! (get active inspector-info) ERR-NOT-AUTHORIZED)
    (asserts! (not (> safety-score u100)) ERR-INVALID-INPUT)
    (asserts! (not (> educational-score u100)) ERR-INVALID-INPUT)

    (map-set facility-inspections
      { inspection-id: inspection-id }
      {
        facility-id: facility-id,
        inspector: tx-sender,
        inspection-date: block-height,
        inspection-type: inspection-type,
        safety-score: safety-score,
        educational-score: educational-score,
        staff-qualifications: staff-qualifications,
        background-checks-current: background-checks-current,
        ratio-compliant: ratio-compliant,
        facility-condition: facility-condition,
        violations: violations,
        overall-rating: overall-rating,
        notes: notes
      }
    )

    ;; Update facility compliance rating
    (map-set childcare-facilities
      { facility-id: facility-id }
      (merge facility {
        compliance-rating: overall-rating,
        last-inspection: block-height,
        license-status: (if (is-eq overall-rating "EXCELLENT") "ACTIVE"
                          (if (is-eq overall-rating "GOOD") "ACTIVE"
                            (if (is-eq overall-rating "NEEDS_IMPROVEMENT") "CONDITIONAL" "SUSPENDED")))
      })
    )

    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Update enrollment count
(define-public (update-enrollment (facility-id uint) (new-enrollment uint))
  (let ((facility (unwrap! (map-get? childcare-facilities { facility-id: facility-id }) ERR-FACILITY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner facility)) ERR-NOT-AUTHORIZED)
    (asserts! (not (> new-enrollment (get capacity facility))) ERR-INVALID-INPUT)
    (map-set childcare-facilities
      { facility-id: facility-id }
      (merge facility { current-enrollment: new-enrollment })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get facility details
(define-read-only (get-childcare-facility (facility-id uint))
  (map-get? childcare-facilities { facility-id: facility-id })
)

;; Get inspection details
(define-read-only (get-childcare-inspection (inspection-id uint))
  (map-get? facility-inspections { inspection-id: inspection-id })
)

;; Get staff member details
(define-read-only (get-staff-member (facility-id uint) (staff-member principal))
  (map-get? staff-records { facility-id: facility-id, staff-member: staff-member })
)

;; Get childcare inspector details
(define-read-only (get-childcare-inspector (inspector principal))
  (map-get? childcare-inspectors { inspector: inspector })
)

;; Check if facility is compliant
(define-read-only (is-facility-compliant (facility-id uint))
  (match (map-get? childcare-facilities { facility-id: facility-id })
    facility (or (is-eq (get compliance-rating facility) "EXCELLENT") (is-eq (get compliance-rating facility) "GOOD"))
    false
  )
)

;; Private Functions

;; Check staff-to-child ratio compliance
(define-private (check-staff-child-ratio (facility-id uint) (enrollment uint) (staff-count uint))
  (if (is-eq enrollment u0)
    true
    (not (< staff-count (/ (+ enrollment u5) u6)))
  )
)

;; Determine overall childcare rating
(define-private (determine-childcare-rating (safety-score uint) (educational-score uint) (staff-qual bool) (bg-checks bool) (ratio-ok bool) (violation-count uint))
  (let ((avg-score (/ (+ safety-score educational-score) u2)))
    (if (and (>= avg-score u90) staff-qual bg-checks ratio-ok (is-eq violation-count u0))
      "EXCELLENT"
      (if (and (>= avg-score u80) staff-qual bg-checks ratio-ok (<= violation-count u1))
        "GOOD"
        (if (and (>= avg-score u70) ratio-ok (<= violation-count u3))
          "NEEDS_IMPROVEMENT"
          "UNSATISFACTORY"
        )
      )
    )
  )
)
