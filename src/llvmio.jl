## --- The basics of basics: putchar

putchar(c::Char) = putchar(UInt8(c))
function putchar(c::UInt8)
    Base.llvmcall(("""
    ; External declaration of the puts function
    declare i32 @putchar(i8 nocapture) nounwind

    define i32 @main(i8) {
    entry:
        %call = call i32 (i8) @putchar(i8 %0)
        ret i32 0
    }
    """, "main"), Int32, Tuple{UInt8}, c)
end

newline() = putchar(0x0a)

## --- The old reliable: puts

puts(s::AbstractMallocdMemory) = puts(pointer(s))
puts(s) = GC.@preserve s puts(pointer(s))
function puts(p::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the puts function
    declare i32 @puts(i8* nocapture) nounwind

    define i32 @main(i8*) {
    entry:
        %call = call i32 (i8*) @puts(i8* %0)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, p)
end


## --- File IO primitives

struct FILE end

fopen(name::AbstractMallocdMemory, mode::AbstractMallocdMemory) = fopen(pointer(name), pointer(mode))
fopen(name, mode) = GC.@preserve name mode fopen(pointer(name), pointer(mode))
function fopen(name::Ptr{UInt8}, mode::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the fopen function
    declare i8* @fopen(i8*, i8*)

    define i8* @main(i8* %name, i8* %mode) {
    entry:
        %fp = call i8* (i8*, i8*) @fopen(i8* %name, i8* %mode)
        ret i8* %fp
    }
    """, "main"), Ptr{FILE}, Tuple{Ptr{UInt8}, Ptr{UInt8}}, name, mode)
end

function fclose(fp::Ptr{FILE})
    Base.llvmcall(("""
    ; External declaration of the fclose function
    declare i32 @fclose(i8*)

    define i32 @main(i8* %fp) {
    entry:
        %status = call i32 (i8*) @fclose(i8* %fp)
        ret i32 %status
    }
    """, "main"), Int32, Tuple{Ptr{FILE}}, fp)
end

## --- printf/fprintf, just a string

printf(s::AbstractMallocdMemory) = printf(pointer(s))
printf(s) = GC.@preserve s printf(pointer(s))
fprintf(fp::Ptr{FILE}, s::AbstractMallocdMemory) = printf(fp::Ptr{FILE}, pointer(s))
fprintf(fp::Ptr{FILE}, s) = GC.@preserve s printf(fp::Ptr{FILE}, pointer(s))
function printf(s::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}}, s)
end
function fprintf(fp::Ptr{FILE}, s::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the fprintf function
    declare i32 @fprintf(i8*, i8*)

    define i32 @main(i8* %fp, i8* %str) {
    entry:
        %status = call i32 (i8*, i8*) @fprintf(i8* %fp, i8* %str)
        ret i32 %status
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}}, fp, s)
end
newline(fp::Ptr{FILE}) = fprintf(fp, c"\n")

## --- printf/fprintf, with a format string, just like in C

printf(fmt::AbstractMallocdMemory, s::AbstractMallocdMemory) = printf(pointer(fmt), pointer(s))
printf(fmt, s) = GC.@preserve fmt s printf(pointer(fmt), pointer(s))
fprintf(fp::Ptr{FILE}, fmt::AbstractMallocdMemory, s::AbstractMallocdMemory) = printf(fp::Ptr{FILE}, pointer(fmt), pointer(s))
fprintf(fp::Ptr{FILE}, fmt, s) = GC.@preserve fmt s printf(fp::Ptr{FILE}, pointer(fmt), pointer(s))
function printf(fmt::Ptr{UInt8}, s::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i8*) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i8* %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Ptr{UInt8}}, fmt, s)
end
function fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, s::Ptr{UInt8})
    Base.llvmcall(("""
    ; External declaration of the fprintf function
    declare i32 @fprintf(i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt, i8* %str) {
    entry:
        %status = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i8* %str)
        ret i32 %status
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, Ptr{UInt8}}, fp, fmt, s)
end


printf(fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(pointer(fmt), n)
printf(fmt::MallocString, n::Union{Number, Ptr}) = printf(pointer(fmt), n)
fprintf(fp::Ptr{FILE}, fmt::StaticString, n::Union{Number, Ptr}) = GC.@preserve fmt printf(fp::Ptr{FILE}, pointer(fmt), n)
fprintf(fp::Ptr{FILE}, fmt::MallocString, n::Union{Number, Ptr}) = printf(fp::Ptr{FILE}, pointer(fmt), n)

# Floating point numbers
function printf(fmt::Ptr{UInt8}, n::Float64)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, double) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, double %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, Float64}, fmt, n)
end
function fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::Float64)
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @fprintf(i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt, double %n) {
    entry:
        %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, double %n)
        ret i32 %call
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, Float64}, fp, fmt, n)
end

# Just convert all other Floats to double
fprintf(fmt::Ptr{UInt8}, n::AbstractFloat) = printf(fmt::Ptr{UInt8}, Float64(n))
fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::AbstractFloat) = printf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, Float64(n))

# Integers
function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i64) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i64 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int64, UInt64, Ptr}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @fprintf(i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt, i64 %n) {
    entry:
        %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i64 %n)
        ret i32 %call
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
end

function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i32) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i32 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int32, UInt32}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @fprintf(i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt, i32 %n) {
    entry:
        %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i32 %n)
        ret i32 %call
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
end

function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i16) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i16 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int16, UInt16}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @fprintf(i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt, i16 %n) {
    entry:
        %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i16 %n)
        ret i32 %call
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
end

function printf(fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @printf(i8*, ...)

    define i32 @main(i8*, i8) {
    entry:
        %call = call i32 (i8*, ...) @printf(i8* %0, i8 %1)
        ret i32 0
    }
    """, "main"), Int32, Tuple{Ptr{UInt8}, T}, fmt, n)
end
function fprintf(fp::Ptr{FILE}, fmt::Ptr{UInt8}, n::T) where T <: Union{Int8, UInt8}
    Base.llvmcall(("""
    ; External declaration of the printf function
    declare i32 @fprintf(i8*, ...)

    define i32 @main(i8* %fp, i8* %fmt, i8 %n) {
    entry:
        %call = call i32 (i8*, ...) @fprintf(i8* %fp, i8* %fmt, i8 %n)
        ret i32 %call
    }
    """, "main"), Int32, Tuple{Ptr{FILE}, Ptr{UInt8}, T}, fp, fmt, n)
end

## ---

# Pick a printf format string depending on the type
printfmt(::Type{<:AbstractFloat}) = c"%e"
printfmt(::Type{<:Integer}) = c"%d"
printfmt(::Type{<:Ptr})  = c"Ptr @0x%016x" # Assume 64-bit pointers
printfmt(::Type{UInt64}) = c"0x%016x"
printfmt(::Type{UInt32}) = c"0x%08x"
printfmt(::Type{UInt16}) = c"0x%04x"
printfmt(::Type{UInt8})  = c"0x%02x"
printfmt(::Type{<:Union{MallocString, StaticString}}) = c"\"%s\"" # Can I offer you a string in this trying time?

# Top-level formats, single numbers
function printf(n::T) where T <: Union{Number, Ptr}
    printf(printfmt(T), n)
    newline()
end

# Print a vector
function printf(v::AbstractVector{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(p, v[i])
        newline()
    end
    return 0
end

# Print a tuple
function printf(v::NTuple{N, T} where N) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    putchar(0x28) # open paren
    @inbounds GC.@preserve fmt for i ∈ eachindex(v)
        printf(p, v[i])
        putchar(0x2c) # comma
        putchar(0x20) # space
    end
    putchar(0x29) # close paren
    newline()
end

# Print a 2d matrix
function printf(m::AbstractMatrix{T}) where T <: Union{Number, Ptr, StaticString}
    fmt = printfmt(T)
    p = pointer(fmt)
    @inbounds GC.@preserve fmt for i ∈ axes(m,1)
        for j ∈ axes(m,2)
            printf(p, m[i,j])
            putchar(0x09) # tab
        end
        newline()
    end
    return 0
end


## ---
