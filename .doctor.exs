%Doctor.Config{
  ignore_paths: [
    ~r(apps/.*/test/),
    ~r(config/),
    ~r(mix\.exs$),
    ~r(apps/.*/lib/.*/application\.ex$)
  ],
  min_module_doc_coverage: 100,
  min_overall_doc_coverage: 100,
  min_overall_moduledoc_coverage: 100,
  raise: false,
  reporter: Doctor.Reporters.Short,
  struct_type_spec_required: false,
  exception_moduledoc_required: true
}
