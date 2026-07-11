using Preferences

# Control whether timings are enabled or not, by default yes.
# Note: TimerOutputs is not thread-safe, so do not use `@timeit`
# or `@timing` in threaded regions unless you know what you are doing.

"""TimerOutput object used to store LOBPCG timings."""
const timer = TimerOutput()

# When `@timing` wraps a function definition, TimerOutputs macroexpands the whole body and
# buries it inside a try/finally. A leading `@nospecialize` only takes effect as a
# method-level declaration, i.e. at the top level of the method body; buried in a
# try/finally it is silently ignored. So we lift any leading `@nospecialize` statements out
# of the body before timing (returning them), to be spliced back in at the top of the timed
# method body. Returns an empty vector if `ex` is not such a function definition.
function _lift_leading_nospecialize!(ex)
    (ex isa Expr && (ex.head === :function || Base.is_short_function_def(ex))) || return Any[]
    body = ex.args[2]
    (body isa Expr && body.head === :block) || return Any[]
    lifted, kept, still_leading = Any[], Any[], true
    for stmt in body.args
        if still_leading && Meta.isexpr(stmt, :macrocall) && stmt.args[1] === Symbol("@nospecialize")
            push!(lifted, stmt)
        else
            still_leading &= stmt isa LineNumberNode
            push!(kept, stmt)
        end
    end
    empty!(body.args); append!(body.args, kept)
    lifted
end

"""
Shortened version of the `@timeit` macro from `TimerOutputs`,
which writes to the LOBPCG timer.
"""
macro timing(args...)
    @static if @load_preference("timer_enabled", "true") == "true"
        lifted = _lift_leading_nospecialize!(last(args))
        # Copy of https://github.com/KristofferC/TimerOutputs.jl/blob/master/src/TimerOutput.jl#L174
        # because macros calling macros does not work easily in Julia
        blocks = TimerOutputs.timer_expr(__source__, __module__, false,
                                         :($(LOBPCG.timer)), args...)
        if blocks isa Expr
            if !isempty(lifted)
                # `blocks` is `esc(function … end)`; put the `@nospecialize` back at the top
                # of the (timed) method body so it lands at method top level.
                fn = Meta.isexpr(blocks, :escape) ? blocks.args[1] : blocks
                prepend!(fn.args[2].args, lifted)
            end
            blocks
        else
            Expr(:block,
                blocks[1],                  # the timing setup
                Expr(:tryfinally,
                    :($(esc(args[end]))),   # the user expr
                    :($(blocks[2]))         # the timing finally
                )
            )
        end
    else  # Disable taking timings
        :($(esc(last(args))))
    end
end

function set_timer_enabled!(state=true)
    @set_preferences!("timer_enabled" => string(state))
    @info "timer_enabled preference changed. This is a permanent change, restart julia to see the effect."
end
