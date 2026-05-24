function fish_right_prompt --description 'Write out the right prompt'
    set_color cyan
    date "+%I:%M:%S %p"
    set_color normal
end
