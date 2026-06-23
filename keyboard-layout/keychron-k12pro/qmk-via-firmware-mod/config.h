#pragma once

#define DYNAMIC_KEYMAP_LAYER_COUNT 5

// Włącza Kinetic Mouse Keys
#define MK_KINETIC_SPEED

// Domyślne wartości Kinetic Mode
#define MOUSEKEY_DELAY 5
#define MOUSEKEY_INTERVAL 10
#define MOUSEKEY_MOVE_DELTA 16

#define MOUSEKEY_INITIAL_SPEED 70
#define MOUSEKEY_BASE_SPEED 4500
#define MOUSEKEY_DECELERATED_SPEED 250
#define MOUSEKEY_ACCELERATED_SPEED 3500

// Domyślne wartości Kinetic Mode dla scrolla
#define MOUSEKEY_WHEEL_INITIAL_MOVEMENTS 16
#define MOUSEKEY_WHEEL_BASE_MOVEMENTS 32
#define MOUSEKEY_WHEEL_ACCELERATED_MOVEMENTS 48
#define MOUSEKEY_WHEEL_DECELERATED_MOVEMENTS 8

// #pragma once

// #define DYNAMIC_KEYMAP_LAYER_COUNT 5

// // ===== ACCELERATED MODE =====
// // Bez #define MK_KINETIC_SPEED

// // Ruch kursora
// #define MOUSEKEY_DELAY 10
// #define MOUSEKEY_INTERVAL 20

// // Mały pierwszy krok — dzięki temu MS_ACL0 będzie precyzyjny i wolny,
// // zbliżony do początku ruchu w Twoim obecnym kinetic.
// #define MOUSEKEY_MOVE_DELTA 2

// // Normalny ruch bez MS_ACLx: standardowy QMK max speed.
// #define MOUSEKEY_MAX_SPEED 10
// #define MOUSEKEY_TIME_TO_MAX 30

// // Scroll — domyślne wartości QMK
// #define MOUSEKEY_WHEEL_DELAY 10
// #define MOUSEKEY_WHEEL_INTERVAL 80
// #define MOUSEKEY_WHEEL_DELTA 1
// #define MOUSEKEY_WHEEL_MAX_SPEED 8
// #define MOUSEKEY_WHEEL_TIME_TO_MAX 40
