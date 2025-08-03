# Public Health Inspection and Regulatory Compliance System

A blockchain-based system for managing public health inspections and regulatory compliance across various establishment types.

## Overview

This system provides transparent, immutable tracking of health inspections and regulatory compliance for:

- Food establishments (restaurants, cafes, food trucks)
- Swimming pools and aquatic facilities
- Childcare facilities (daycares, preschools)
- Tattoo and piercing shops
- Public events and gatherings

## Smart Contracts

### 1. Food Establishment Inspection (`food-inspection.clar`)
Manages health department inspections of restaurants and food facilities including:
- Inspection scheduling and tracking
- Violation recording and severity classification
- Permit status management
- Inspector assignment and certification

### 2. Swimming Pool Safety Monitoring (`pool-safety.clar`)
Ensures public pools meet health and safety standards through:
- Water quality testing schedules
- Chemical level monitoring
- Safety equipment inspections
- Lifeguard certification tracking

### 3. Childcare Facility Inspection (`childcare-inspection.clar`)
Monitors daycare centers and preschools for safety and quality via:
- Background check verification
- Facility safety inspections
- Staff-to-child ratio monitoring
- Educational program compliance

### 4. Tattoo and Piercing Shop Regulation (`body-art-regulation.clar`)
Ensures body art establishments follow health regulations including:
- Sterilization equipment monitoring
- Artist licensing verification
- Health permit tracking
- Infection control compliance

### 5. Public Event Health Oversight (`event-oversight.clar`)
Manages health permits and inspections for festivals and gatherings through:
- Event permit applications
- Crowd capacity management
- Food vendor oversight
- Emergency preparedness verification

## Key Features

- **Immutable Records**: All inspection data stored permanently on blockchain
- **Transparent Compliance**: Public access to establishment compliance status
- **Automated Scheduling**: Smart contract-based inspection scheduling
- **Multi-stakeholder Access**: Different permission levels for inspectors, establishments, and public
- **Violation Tracking**: Comprehensive violation history and resolution tracking

## Data Structures

Each contract maintains:
- Establishment registry with unique identifiers
- Inspector credentials and assignments
- Inspection schedules and results
- Violation records and remediation status
- Permit and license tracking

## Compliance Levels

- **COMPLIANT**: Meets all regulatory requirements
- **MINOR_VIOLATIONS**: Non-critical issues requiring attention
- **MAJOR_VIOLATIONS**: Serious issues requiring immediate action
- **SUSPENDED**: Operations suspended due to critical violations
- **REVOKED**: Permits permanently revoked

## Getting Started

1. Deploy contracts to Stacks blockchain
2. Register health department as contract owner
3. Add certified inspectors to system
4. Register establishments for monitoring
5. Begin automated inspection scheduling

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

Tests cover all contract functions, edge cases, and security scenarios using Vitest framework.

## Security Considerations

- Only certified inspectors can record inspection results
- Establishment owners can view their records but cannot modify inspection data
- Public can access compliance status but not detailed violation information
- Contract owner (health department) has administrative privileges

## Deployment

Configure your Clarinet.toml file and deploy using:
\`\`\`bash
clarinet deploy
\`\`\`

## License

MIT License - See LICENSE file for details
