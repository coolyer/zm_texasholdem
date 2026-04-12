# ♠️ Texas Hold'em Poker Script for BO3

**Author:** Coolyer  
**⚠️ Please credit if used.**
** STILL WIP THERE A LOT OF ERROR RN**

---

## 📥 Installation

1. Copy the **scripts** folder into the root of your BO3 directory.  #
2. Copy the **_custom** folder into the root of your BO3 directory. 
3. Place **zm_texas.gsc** (and any related files) into your `usermaps/scripts/zm/` folder.  
4. Add your own card and poker table sound files if desired.

---

## 🔧 Integration


### 1. Radiant Setup
- Place one or more `trigger_use` entities where you want the poker table.
- Set their `targetname` to:
```c
poker_table
```
### 2. Script Setup (GSC)

* Add this line near the top with your other #using lines:
```
#using scripts\zm\zm_texas;
```
* In your main setup function (main() or startround()), add:
```
thread zm_texas::init_texas_poker();
```
### 3. Zone File (.zone)
* Add this line:
```
include,zm_texas
```

❤️ Support the Project

If you enjoy this work and want to support future development, consider donating:

[👉 PayPal – Coolyer](https://www.paypal.com/paypalme/coolyer)