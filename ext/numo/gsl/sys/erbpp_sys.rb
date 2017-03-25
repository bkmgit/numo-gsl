require_relative "../gen/erbpp2"
require "erbpp/line_number"

def read_eval(file)
  fn = file % `gsl-config --version`.chomp
  fn = file % "def" unless File.exist?(fn)
  File.exist?(fn) ? eval(open(fn).read) : []
end

def read_func
  read_eval("func_%s.rb")
end

def read_const
  read_eval("const_%s.rb")
end

def read_enum
  read_eval("enum_%s.rb")
end

func_list = read_func
const_list = read_const
enum_list = read_enum

prec_list = %w[
GSL_PREC_DOUBLE
GSL_PREC_SINGLE
GSL_PREC_APPROX
GSL_MODE_DEFAULT
]

def find_template(h)
  func_type = h[:func_type]
  arg_types = h[:args].map{|a| a[0].sub(/^const /,"")}
  if /This function is now deprecated/m =~ h[:desc]
    $stderr.puts "depricated: #{h[:func_name]}"
    return nil
  end
  case func_type
  when "int"
    case arg_types
    when ["double"];                 "m_Int_f_DFloat"
    when ["double"]*3;               "m_Int_f_DFloat_x3" # gsl_fcmp
    end
  when "double"
    case arg_types
    when ["double"];                 "m_DFloat_f_DFloat"
    when ["double"]*2;               "m_DFloat_f_DFloat_x2"
    when ["double"]*3;               "m_DFloat_f_DFloat_x3"
    when ["int"];                    "m_DFloat_f_Int"
    when ["double","int"];           "m_DFloat_f_DFloat_Int"
    when ["double","int *"];         "m_DFloat_Int_f_DFloat"  # gsl_frexp
    when ["double","unsigned int"];  "m_DFloat_f_DFloat_UInt"
    end
  end
end

DefLib.new(nil,'lib') do
  set erb_dir: %w[tmpl ../gen/tmpl]
  set erb_suffix: ".c"

  set file_name: "gsl_sys.c"
  set include_files: %w[gsl/gsl_sys.h gsl/gsl_pow_int.h gsl/gsl_math.h gsl/gsl_mode.h]
  set lib_name: "sys"
  set ns_var: "mGSL"

  def_module('module') do
    set name: "sys"
    set module_name: "GSL"
    set module_var: "mGSL"
    set full_module_name: "Numo::GSL"

    func_list.each do |h|
      if t = find_template(h)
        m = h[:func_name].sub(/^gsl_/,"")
        def_method(m, t, **h)
      else
        $stderr.puts "skip "+h[:func_name]
      end
    end

    const_list.each do |a|
      m = a[0]
      v = "DBL2NUM(#{a[0]})"
      def_const(m, v, desc:a[1]||"")
    end

    prec_list.each do |a|
      m = a.sub(/GSL_/,"")
      v = "INT2FIX(#{a})"
      def_const(m, v, desc:"")
    end

    enum_list.each do |a|
      m = a[0].sub(/GSL_/,"")
      v = "INT2FIX(#{a[1]})"
      def_const(m, v, desc:a[2]||"")
    end
  end

end.run