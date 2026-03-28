## DebugConfig.gd
## Centralized debug toggles. Change these values here to enable or
## disable cat abilities without hunting through individual scripts.
extends Node

## Hermes Cat — grants the player a dash ability.
@export var hermes_cat_enabled: bool = true

## QR Cat — lets the player receive orders by clicking seated customers.
@export var qr_cat_enabled: bool = false

## Queue Cat — lets the player click waiting groups to seat them immediately.
@export var queue_cat_enabled: bool = true

## Money Cat — auto-collects payment from tables when customers finish eating.
@export var money_cat_enabled: bool = true

## Counter Cat — unlocks the countertop plates for staging food items.
@export var counter_cat_enabled: bool = true
