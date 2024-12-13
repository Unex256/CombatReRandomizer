local baseUniques = [[{
    "UniqueTypes": {
      "Celestial Shield": {
        "boosts": {
          "ActionResource": [
            { "type": "ActionPoint", "amount": 1, "percentage": false },
            { "type": "Movement", "amount": 3 }
          ],
          "TemporaryHp": { "amount": 50, "percentage": true },
          "Ability": [
            { "type": "Constitution", "amount": 4 },
            { "type": "Charisma", "amount": 3, "percentage": false }
          ],
          "AC": { "amount": 2, "percentage": true },
          "SpellSlot": [
            { "amount": 3, "level": 4 },
            { "amount": 1, "level": 1 }
          ]
        },
        "statuses": [
          { "type": "GiantKiller", "duration": 8 },
          { "type": "ColossusSlayer" }
        ],
        "blacklist": ["Fiend's Wrath"],
        "whitelist": [],
        "weight": 85
      },
      "Arcane Surge": {
        "boosts": {
          "ActionResource": [
            { "type": "ActionPoint", "amount": 0.6, "percentage": true },
            { "type": "BonusActionPoint", "amount": 0.6, "percentage": true }
          ],
          "TemporaryHp": { "amount": 75 },
          "Ability": [
            { "type": "Intelligence", "amount": 5 },
            { "type": "Wisdom", "amount": 3 }
          ],
          "AC": { "amount": 1 }
        },
        "statuses": [
          { "type": "UncannyDodge", "duration": 6 }
        ],
        "whitelist": ["Celestial Shield"],
        "blacklist": [],
        "weight": 60
      },
      "Fiend's Wrath": {
        "boosts": {
          "ActionResource": [
            { "type": "ActionPoint", "amount": 2 }
          ],
          "Ability": [
            { "type": "Strength", "amount": 6, "percentage": false }
          ],
          "AC": { "amount": 3, "percentage": false }
        },
        "statuses": [
          { "type": "Tough", "duration": 10 }
        ],
        "blacklist": ["Celestial Shield"],
        "whitelist": [],
        "weight": 40
      }
    }
  }
  ]]

return baseUniques