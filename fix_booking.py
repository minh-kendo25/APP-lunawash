import re

with open('lib/screens/booking_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix vehicleTypeId assignment
code = re.sub(r"_savedVehicles\[_selectedSavedVehicleIndex\]\['vehicleTypeId'\] \?\? 'VT-OTO-4C'", r"_savedVehicles[_selectedSavedVehicleIndex]['vehicleTypeId']?.toString() ?? 'VT-OTO-4C'", code)
code = re.sub(r"activeVeh\['vehicleTypeId'\] \?\? 'VT-OTO-4C'", r"activeVeh['vehicleTypeId']?.toString() ?? 'VT-OTO-4C'", code)

# Fix prices and durationMinutes
code = code.replace("['servicePrices']", "['prices']")
code = code.replace("['estimatedDuration']", "['durationMinutes']")

# Fix pkg['id'] assignments
code = code.replace("_selectedMainServiceId = pkg['id'];", "_selectedMainServiceId = pkg['id']?.toString() ?? '';")
code = code.replace("_selectedAddOnIds.add(addOn['id']);", "_selectedAddOnIds.add(addOn['id']?.toString() ?? '');")
code = code.replace("_selectedAddOnIds.remove(addOn['id']);", "_selectedAddOnIds.remove(addOn['id']?.toString() ?? '');")
code = code.replace("serviceIds.add(sp['id']);", "serviceIds.add(sp['id']?.toString() ?? '');")

# Fix Text(vehicle['plate'])
code = code.replace("Text(vehicle['plate'],", "Text(vehicle['license']?.toString() ?? vehicle['plate']?.toString() ?? 'Bi?n s?',")

# Fix Text(_savedVehicles.isEmpty ? 'Chýa có xe' : _savedVehicles[_selectedSavedVehicleIndex]['license'] ?? 'Bi?n s?',
code = code.replace("Text(_savedVehicles.isEmpty ? 'Chýa có xe' : _savedVehicles[_selectedSavedVehicleIndex]['license'] ?? 'Bi?n s?',", "Text(_savedVehicles.isEmpty ? 'Chýa có xe' : (_savedVehicles[_selectedSavedVehicleIndex]['license']?.toString() ?? 'Bi?n s?'),")

# Fix Text(res['error'] ?? 'Ð? x?y ra l?i
code = code.replace("Text(res['error'] ?? 'Ð? x?y ra l?i", "Text(res['error']?.toString() ?? 'Ð? x?y ra l?i")

# Fix Text(type,
code = code.replace("Text(type,", "Text(type.toString(),")

# Save
with open('lib/screens/booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed!")
