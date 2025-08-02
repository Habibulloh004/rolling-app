class AddressDetailModel {
  final Response? response;

  AddressDetailModel({this.response});

  factory AddressDetailModel.fromJson(Map<String, dynamic> json) {
    return AddressDetailModel(
      response:
          json['response'] != null ? Response.fromJson(json['response']) : null,
    );
  }
}

class Response {
  final GeoObjectCollection? geoObjectCollection;

  Response({this.geoObjectCollection});

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      geoObjectCollection: json['GeoObjectCollection'] != null
          ? GeoObjectCollection.fromJson(json['GeoObjectCollection'])
          : null,
    );
  }
}

class GeoObjectCollection {
  final List<FeatureMember>? featureMember;

  GeoObjectCollection({this.featureMember});

  factory GeoObjectCollection.fromJson(Map<String, dynamic> json) {
    var list = json['featureMember'] as List;
    List<FeatureMember> featureMembers =
        list.map((e) => FeatureMember.fromJson(e)).toList();

    return GeoObjectCollection(featureMember: featureMembers);
  }
}

class FeatureMember {
  final GeoObject? geoObject;

  FeatureMember({this.geoObject});

  factory FeatureMember.fromJson(Map<String, dynamic> json) {
    return FeatureMember(
      geoObject: json['GeoObject'] != null
          ? GeoObject.fromJson(json['GeoObject'])
          : null,
    );
  }
}

class GeoObject {
  final MetaDataProperty? metaDataProperty;

  GeoObject({this.metaDataProperty});

  factory GeoObject.fromJson(Map<String, dynamic> json) {
    return GeoObject(
      metaDataProperty: json['metaDataProperty'] != null
          ? MetaDataProperty.fromJson(json['metaDataProperty'])
          : null,
    );
  }
}

class MetaDataProperty {
  final GeocoderMetaData? geocoderMetaData;

  MetaDataProperty({this.geocoderMetaData});

  factory MetaDataProperty.fromJson(Map<String, dynamic> json) {
    return MetaDataProperty(
      geocoderMetaData: json['GeocoderMetaData'] != null
          ? GeocoderMetaData.fromJson(json['GeocoderMetaData'])
          : null,
    );
  }
}

class GeocoderMetaData {
  final Address? address;

  GeocoderMetaData({this.address});

  factory GeocoderMetaData.fromJson(Map<String, dynamic> json) {
    return GeocoderMetaData(
      address:
          json['Address'] != null ? Address.fromJson(json['Address']) : null,
    );
  }
}

class Address {
  final String? formatted;

  Address({this.formatted});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      formatted: json['formatted'],
    );
  }
}
