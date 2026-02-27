# Promo Code Logic Guide

This document walks a new Codex agent through the promo-code implementation so you can trace, extend, or debug the full flow without spelunking the codebase from scratch.

## Core Components
- `Models/CartItem.swift`: Houses `CartManager`, the canonical source of cart items and promotion state (`AppliedPromotion`, discount totals, bonus items).
- `Services/PosterAPIService.swift`: Talks to the Poster backend for promotions (`PosterPromotion`) and bonus product lookups.
- `ContentView.swift`: Wires dependencies into `CartManager` (menu-item lookup, authentication hooks, localization).
- `Screens/CartScreen.swift`: UI surface where users enter codes; it calls `CartManager.applyPromoCode` and displays errors.
- `Services/OrderCalculator.swift`: Consumes the `AppliedPromotion` state when building price breakdowns.

## State Model (`CartManager.AppliedPromotion`)
`AppliedPromotion` snapshots the evaluated promo:
- raw and normalized codes (`inputCode`, `normalizedCode`, `displayCode`)
- `resultType` (percentage vs fixed discount vs bonus products)
- monetary data (`discountAmount`, `discountPercentage`, `percentageBaseAmount`)
- bonus metadata (`bonusRewards`, `bonusQuantity`, `bonusCartItemIds`)
- `minimumOrderAmount` and `satisfiedConditions` for transparency/debugging

`CartManager` exposes published properties (`promoCode`, `promoPercentage`, `promoDiscountAmount`, `appliedPromotion`, etc.) so the UI and calculators react automatically.

## Apply-Promo Flow
1. **Input hygiene** – `applyPromoCode` trims whitespace, uppercases, strips `$`, and keeps alphanumerics via `PosterPromotion.normalizeInputCode`. Empty results throw `.invalidCode`.
2. **Promotion catalog** – `loadPromotionsIfNeeded` fetches `PosterAPIService.fetchPromotions()`, caching for 5 minutes unless `force` is true. Promotions are filtered to only those with a normalized code and sorted by `position` then `name`.
3. **Lookup with retry** – `findPromotion` searches cached results. On miss, promotions refresh once more before surfacing `.invalidCode` or `.promotionsUnavailable`.
4. **First-order guard** – Codes with `FIRST` prefix require `orderCountProvider`. Missing counts invoke `authenticationHandler` and throw `.authenticationRequired`; non-zero counts throw `.notFirstOrder`.
5. **Evaluation** – `evaluatePromotion` performs:
   - Schedule checks (`isPromotionActive`, `promotionScheduleDescription`) validating date range, weekday mask, time windows.
   - Spot restrictions via `availableForSpots`.
   - Birthday promotions (codes prefixed with `BDAY`) enforce authentication and exact birthday match via `birthdayProvider`.
   - Cart analytics: subtotal, per-category/product totals, quantity, etc., excluding bonus items.
   - Condition evaluation (see below) honoring `conditionsRule` (`and`/`or`) and `conditionsExactly`.
6. **Result computation** – Depending on `resultType`, calculates discounts or bonus entitlements:
   - `fixedDiscountAmount`: converts Poster’s cent-based `discountValueRaw` into currency and caps at subtotal.
   - `percentageDiscountOnProducts`: normalizes percentage and computes base amount via `percentageDiscountBaseAmount`.
   - `fixedDiscountOnProducts`: applies per-product/category target prices from `discountPrices`.
   - `bonusProducts`: captures eligible rewards for later syncing.
7. **Bonus item syncing** – `syncBonusItems` resolves `PosterPromotion.PromotionParams.BonusProduct` entries by:
   - Validating reward types (1/2/3 supported) and retrieving menu data via `menuItemProvider` or `PosterAPIService.fetchProduct`.
   - Computing override prices with `computeBonusUnitPrice` according to `bonusProductsConditionType` (percentage, absolute off, fixed price).
   - Injecting bonus `CartItem`s flagged with `isBonus` and tracking their IDs for cleanup.
8. **State commit** – Stores the new `AppliedPromotion`, updates published discount fields, sets `isPromoApplied = true`, and returns the evaluation to the caller (`CartScreen` uses it to show the cleaned display code).

## Condition Types (`PromotionParams.Condition.type`)
These checks gate whether the promo is applicable:
- `0` – Whole-cart spend/quantity thresholds (`sum`, `pcs`). Honors the `conditionsExactly` flag.
- `1` – Category-specific spend/quantity. Fails if no qualifying items are present.
- `2` / `3` – Product-level requirements (Poster treats both as variants of product targeting).

Failures generate localized, user-friendly reasons (e.g., “Add at least X items”) via `ConditionCheck.failureReason`. When multiple conditions fail:
- `AND` rules surface the first failure.
- `OR` rules pick the failure with the largest `requiredAmount` to hint at the next best action.

## Ongoing Revalidation
- Cart mutations (`addItem`, `updateQuantity`, `removeItem`, `clearCart`) call `ensureActivePromotionValid`, which re-runs the evaluation async.
- `revalidateActivePromotion` forces a fresh promotion fetch and repeats evaluation. Any failure resets the promo state (`resetPromotion`).
- `ContentView` observes user profile, menu changes, authentication toggles, and birthdays, calling `revalidatePromotionIfNeeded` so promo eligibility stays accurate.

## Error Surface
`CartManager.PromotionApplicationError` covers domain errors (invalid codes, unmet conditions, first-order or auth requirements, configuration gaps). `CartScreen.resolvePromoErrorMessage` maps these to localized copy and falls back to Poster API error descriptions when network calls fail.

## Interaction with Checkout
- `AppState.placeOrder` calls `makePosterPromotionPayload` to translate the active `AppliedPromotion` into Poster’s order format.
- `OrderCalculator.calculateBreakdown` reads `CartManager.appliedPromotion` for downstream total computations, ensuring discounts and loyalty redemptions align.

## Extending or Debugging Tips
- Use `CartManager.availablePromotions` and `AppliedPromotion.satisfiedConditions` to surface diagnostics in debug UIs if you need more transparency.
- When adding new result types or condition semantics, extend `PromotionParams.ResultType` and the switch in `evaluatePromotion`.
- Bonus-product issues often stem from missing menu data—confirm `menuItemProvider` is registered and Poster API credentials are configured via `PosterAPIConfig`.
- Consider instrumenting with logging (`debugLog`) around `applyPromoCode` and `syncBonusItems` when chasing intermittent failures.

## Quick Reference: Dependency Hooks
Registered in `ContentView.onAppear`:
- `registerMenuItemProvider` – resolves product metadata; needed for bonus rewards.
- `registerOrderCountProvider` – enables first-order checks.
- `registerAuthenticationHandler` – invoked when auth gating fails.
- `registerLocalizationProvider` – ensures errors and schedule strings localize correctly.
- `registerBirthdayProvider` + `registerAuthenticationStatusProvider` – support birthday promos.

Keep these up to date when integrating CartManager outside `ContentView` (e.g., previews or tests) to avoid silent failures.
