@testset "prop graphs" begin
    hr1 = static_dir_graph(5)
    mat = [0 1 0; 1 0 0; 0 1 0] # 1<-->2<--3
    hr2 = static_dir_graph(mat)
    @test EasyABM.all_neighbors(hr2, 1) == [2]
    @test Set(EasyABM.in_neighbors(hr2, 2)) == Set([1,3])
    @test EasyABM.out_neighbors(hr2, 3) == [2]
    gr1 = static_simple_graph(5)
    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    gr2 = static_simple_graph(mat)
    @test Set(EasyABM.all_neighbors(gr2, 2)) == Set([1,3])
end

@testset "misc utilities" begin
    @test dotprod(Vect(1,2), Vect(3,4)) == 11.0
    @test dotprod((1,2),(3,4)) == 11.0
    @test veclength((4,3)) == sqrt(4^2+3^2) 
    @test veclength(Vect(3.0,4.0)) == sqrt(4.0^2+3.0^2)
    @test distance((1,2),(3,4)) == veclength((-2,-2))
    @test moore_distance((1,1),(2,2))==1
    @test manhattan_distance((1,1),(2,2))==2
    @test calculate_direction((0,1)) == 0.0
    @test calculate_direction((-1,0)) == pi/2
    @test calculate_direction((0,-1)) == pi
    @test calculate_direction((1,0)) == 1.5*pi
    @test calculate_direction((eps(Float64),1)) ≈ 2*pi
end