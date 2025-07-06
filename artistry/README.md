# 🎨 Artistry

**Artistry** is a decentralized smart contract built on Clarity for managing a digital art collective. It enables artists to create public or private profiles, showcase their portfolios, verify artwork authenticity, and collaborate with other verified artists in a secure and transparent manner.

---

## ✨ Features

- **Artist Profiles**
  - Register or update artist profile with privacy controls.
  - Mark profiles as verified by the contract owner.

- **Artwork Collections**
  - Create artwork collections with optional completion dates.
  - Add medium, creation details, and privacy levels.

- **Authenticity Certificates**
  - Certify artworks with issue and expiry dates.
  - Includes verification hash and certifier details.
  - Certificates can be verified by the contract owner.

- **Collaboration History**
  - Leave endorsements and reviews for collaborators.
  - Reviews can be public or limited to connected artists.

- **Collective Connections**
  - Send and accept invitations to form a trusted artist collective.
  - Connections enable shared access to semi-private data.

- **Privacy Levels**
  - `PUBLIC`: Visible to anyone.
  - `COLLECTIVE-MEMBERS`: Only visible to connected artists.
  - `PRIVATE`: Visible only to the artist.

---

## 🔐 Access Control

| Function                         | Access       |
|----------------------------------|--------------|
| `verify-artist-profile`         | Admin only   |
| `verify-authenticity-certificate` | Admin only |
| `create/update profile`         | Any user     |
| `add collection/certificate`    | Any user     |
| `endorse collaboration`         | Any user     |
| `send/accept invitations`       | Any user     |
| `set-contract-owner`            | Admin only   |

---

## 🛠 Data Structures

- **artist-profiles**: Maps an artist to profile details.
- **artwork-collections**: Stores collections per artist and ID.
- **authenticity-certificates**: Records authenticity for artworks.
- **collaboration-history**: Tracks peer reviews of collaborations.
- **collective-connections**: Represents pending or accepted invitations.

---

## ⚠️ Error Codes

| Code                | Meaning                        |
|---------------------|--------------------------------|
| `u100`              | Not authorized                 |
| `u101`              | Artist not found               |
| `u102`              | Already endorsed               |
| `u103`              | Invalid privacy level          |
| `u104`              | Certificate not found          |

---

## 📚 Example Usage

```clarity
;; Create a new profile
(create-artist-profile "Amobi" "Digital artist" "https://portfolio.io/amobi" u0)

;; Add an artwork collection
(add-artwork-collection "Abstract Visions" "Oil on Canvas" 1934554 none "A journey through color" u1)

;; Certify an artwork
(add-authenticity-certificate "Abstract Visions #1" "VerifiedGallery" 1934554 none "QmHASHVALUE" u0)

;; Endorse a collaboration
(endorse-collaboration 'SP2...abcd "Vision Project" "Great work!" true)
