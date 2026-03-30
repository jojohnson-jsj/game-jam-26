## DebugConfig.gd
## Centralized debug toggles. Change these values here to enable or
## disable cat abilities without hunting through individual scripts.
extends Node

## Hermes Cat — grants the player a dash ability.
@export var hermes_cat_enabled: bool = false

## QR Cat — lets the player receive orders by clicking seated customers.
@export var qr_cat_enabled: bool = false

## Queue Cat — lets the player click waiting groups to seat them immediately.
@export var queue_cat_enabled: bool = false

## Money Cat — auto-collects payment from tables when customers finish eating.
@export var money_cat_enabled: bool = false

## Counter Cat — unlocks the countertop plates for staging food items.
@export var counter_cat_enabled: bool = false

## Trash Cat — lets the player click the trash can to discard inventory.
@export var trash_cat_enabled: bool = false

## Hopper Cat — adds an extra inventory slot.
@export var hopper_cat_enabled: bool = false

## Patience Bar — shows a progress bar above seated customers' heads.
@export var patience_bar_enabled: bool = true

## Day duration in seconds. Default is 120.
@export var day_duration: float = 60.0

## Starting money for testing. Set to 0 for normal gameplay.
@export var starting_money: float = 0.0
