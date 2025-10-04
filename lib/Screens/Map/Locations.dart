import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/Location.dart';
import '../../Localzition/locals.dart';
import 'map_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  
  // Helper method to format address for display
  String _getDisplayName(Map locationData) {
    // Use shortName if available, otherwise use name, with fallback
    String name = locationData['shortName'] ?? locationData['name'] ?? 'Unknown Location';
    
    // If it's coordinates or error messages, make them more user-friendly
    if (name.startsWith('Location:')) {
      return 'Saved Location (${name.substring(9)})';
    }
    if (name.startsWith('Unable to') || name.startsWith('Address resolution')) {
      return 'Custom Location';
    }
    
    // For full addresses, show the first meaningful part
    if (locationData['shortName'] == null && locationData['name'] != null) {
      String fullName = locationData['name'];
      if (fullName.length > 35) {
        List<String> parts = fullName.split(',');
        if (parts.isNotEmpty) {
          String firstPart = parts.first.trim();
          // Try to include more context if first part is very short
          if (firstPart.length < 20 && parts.length > 1) {
            String secondPart = parts[1].trim();
            String combined = "$firstPart, $secondPart";
            if (combined.length <= 35) {
              return combined;
            }
          }
          return firstPart.length > 35 ? firstPart.substring(0, 32) + "..." : firstPart;
        }
        return fullName.substring(0, 32) + "...";
      }
      return fullName;
    }
    
    return name;
  }
  
  // Helper method to get subtitle/secondary text for full addresses
  String? _getSubtitle(Map locationData) {
    String fullName = locationData['name'] ?? '';
    String shortName = locationData['shortName'] ?? locationData['name'] ?? '';
    
    // Skip subtitle for error messages or coordinates
    if (fullName.startsWith('Location:') || 
        fullName.startsWith('Unable to') || 
        fullName.startsWith('Address resolution') ||
        fullName.startsWith('Custom Location')) {
      return null;
    }
    
    // If we have both full and short names, show the remaining part as subtitle
    if (fullName.length > shortName.length && fullName != shortName) {
      String remaining = fullName.substring(shortName.length);
      if (remaining.startsWith(', ')) {
        remaining = remaining.substring(2);
      }
      if (remaining.isNotEmpty && remaining.length > 5) {
        return remaining.length > 60 ? remaining.substring(0, 57) + "..." : remaining;
      }
    }
    
    // If we don't have shortName (old format), try to create subtitle from full name
    if (locationData['shortName'] == null && locationData['name'] != null) {
      String fullName = locationData['name'];
      List<String> parts = fullName.split(',');
      
      if (parts.length > 1) {
        String displayName = _getDisplayName(locationData);
        
        // Find which parts are already shown in display name
        int displayParts = 1;
        if (displayName.contains(',')) {
          displayParts = ','.allMatches(displayName).length + 1;
        }
        
        if (parts.length > displayParts) {
          String remaining = parts.skip(displayParts).join(', ').trim();
          if (remaining.isNotEmpty && remaining.length > 5) {
            return remaining.length > 60 ? remaining.substring(0, 57) + "..." : remaining;
          }
        }
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            try {
              if (Get.isSnackbarOpen) {
                Get.closeCurrentSnackbar();
              }
            } catch (_) {}
            Navigator.of(context).maybePop();
          },
          color: cDarkGreen,
        ),
        title:
            cAppBarTittle(text: "${LocaleData.myaddresses.getString(context)}"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: cDarkGreen,
              size: 35,
            ), // Replace with an SVG if you have a specific icon
            onPressed: () {
              Get.to(MapScreen(), arguments: {'action': 'add'})?.then((value) {
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: ListView.builder(
          itemCount: MapLocation.getLength(), // 100 list items
          itemBuilder: (context, index) {
            Map locationData = MapLocation.getLocationAt(index);
            String displayName = _getDisplayName(locationData);
            String? subtitle = _getSubtitle(locationData);
            
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: cDarkGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 15,
                                color: cWhite,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cWhite.withOpacity(0.8),
                                  fontWeight: FontWeight.w300,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Show coordinates for reference if it's a custom location
                            if (locationData['lat'] != null && locationData['lon'] != null &&
                                (displayName.contains('Custom Location') || displayName.contains('Saved Location'))) ...[
                              SizedBox(height: 2.h),
                              Text(
                                "Lat: ${locationData['lat'].toStringAsFixed(4)}, Lon: ${locationData['lon'].toStringAsFixed(4)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cWhite.withOpacity(0.6),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.my_location,
                        size: 37,
                        color: cWhite,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(MapScreen(),
                                    arguments: {'action': 'edit', 'id': index})?.then((value) {
                                  setState(() {});
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: cWhite,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    "${LocaleData.edit.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: cDarkGreen,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  MapLocation.deleteAt(index);
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: cWhite,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    "${LocaleData.delete.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: cDarkGreen,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
