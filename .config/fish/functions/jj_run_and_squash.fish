function jj_run_and_squash -a revset cmd -d "Serially run a command and squash it on a jj revset in topological order"
    if test -z "$revset"; or test -z "$cmd"
        echo "Error: Please provide a jj revset and a command."
        echo "Usage: jj_run_and_squash '<revset>' '<command>'"
        return 1
    end

    # jj log inherently outputs in reverse-topological order (children first, parents last). We use
    # --reversed to undo that. 
    # We use --no-graph to get a clean list of short IDs.
    set -l topo_sorted_changes (jj log -r "$revset" -T 'change_id.short() ++ "\n"' --no-graph --reversed)

    if test -z "$topo_sorted_changes"
        echo "No changes found for revset: $revset"
        return 1
    end

    # Join the array with a comma and a space, then print it
    set -l joined_changes (string join ', ' $topo_sorted_changes)
    echo "--> Planned execution order: $joined_changes"
    echo "------------------------------------------------"

    for change in $topo_sorted_changes
        echo "--> Processing change (in order): $change"
        
        # Run the command sequence
        jj new $change; and eval $cmd; and jj squash
        or begin
            echo "--> Failed on change $change. Aborting sequence."
            return 1
        end
    end
    
    echo "--> All changes processed successfully in the correct order!"
end
