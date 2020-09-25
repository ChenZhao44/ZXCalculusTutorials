# ZXCalculusTutorials
An introduction to ZXCalculus.jl

# How to use

Please make sure that Julia (version >= 1.4) is installed.

1. Clone this repo to your device
2. Change the directory of your terminal to the directory of the local repo. For example 
```
$ cd ~/ZXCalculusTutorials
```
3. Run Julia REPL with
```
$ julia --project
```
4. Press `]` to enter the Pkg mode of Julia REPL and enter the following command.
```julia-repl
(ZXCalculusTutorials) pkg> instantiate
```
It will automatically install all required packages.
5. Quit the Pkg mode and use the following command to run the Pluto notebooks.
```julia-repl
julia> using Pluto

julia> Pluto.run()

```
6. Open the file `ZXCalculus-introduction.jl` in this repo with Pluto. And you can see the notebook.
