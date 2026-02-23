cd packages/puer_time_travel_devtools_extension;
fvm flutter pub get;
fvm dart run devtools_extensions build_and_copy --source=. --dest=../puer_time_travel/extension/devtools
fvm dart run devtools_extensions validate --package=../puer_time_travel
