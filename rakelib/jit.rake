namespace :jit do
  task :generate_header do
    classes = %w!rubinius::ObjectHeader
                 rubinius::Object
                 rubinius::CallFrame
                 rubinius::UnwindInfo
                 rubinius::VariableScope
                 rubinius::CompiledMethod
                 rubinius::Executable
                 rubinius::Dispatch
                 rubinius::Arguments
                 rubinius::Tuple
                 rubinius::Array
                 rubinius::Class
                 rubinius::Module
                 rubinius::StaticScope
                 rubinius::InstructionSequence
                 rubinius::SendSite
                 rubinius::SendSite::Internal
                 jit_state!
    require 'tempfile'

    files = %w!vm/call_frame.hpp vm/arguments.hpp vm/dispatch.hpp vm/builtin/sendsite.hpp!
    path = "llvm-type-temp.cpp"

    File.open(path, "w+") do |f|
      files.each do |file|
        f.puts "#include \"#{file}\""
      end

      i = 0
      classes.each do |klass|
        f.puts "void useme#{i}(#{klass}* thing);"
        f.puts "void blah#{i}(#{klass}* thing) { useme#{i}(thing); }"
        i += 1
      end
    end

    str = `llvm-g++ -I. -Ivm -Ivm/external_libs/libtommath -emit-llvm -S -o - "#{path}"`

    types = []

    str.split("\n").each do |line|
      classes.each do |klass|
        if /%"?struct.#{klass}(::\$[^\s]+)?"? = type/.match(line)
          types << line
        end
      end
    end

    opaque = %w!VM TypeInfo VMMethod Fixnum Symbol Selector!

    File.open("vm/gen/types.ll","w+") do |f|
      opaque.each do |o|
        f.puts "%\"struct.rubinius::#{o}\" = type opaque"
      end
      f.puts(*types)
    end

    `llvm-as < vm/gen/types.ll > vm/gen/types.bc`
    `llc -march=cpp -cppgen=contents -f -o vm/gen/types.cpp vm/gen/types.bc`
  end
end
