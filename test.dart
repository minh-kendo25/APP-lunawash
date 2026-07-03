void main() { try { dynamic a = null; String b = a; } catch (e) { print("TEST 1: $e"); } try { dynamic a = null; List b = a as List; } catch (e) { print("TEST 2: $e"); } }
