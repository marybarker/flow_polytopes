newPackage(
    "ThinSincereQuivers",
    Headline => "Construction of flow polytopes and their associated quivers in arbitrary (up to computing power) dimension",
    Version => "0.0",
    Date => "November 20, 2019",
    Authors => {
        {Name => "Mary Barker",
         Email => "marybarker@wustl.edu",
         HomePage => "https://github.com/marybarker"}, 
        {Name => "Patricio Gallardo",
         Email => "pgallard@ucr.edu",
         HomePage => "http://patriciogallardo.com/"
        }
    },
    PackageImports => {"Graphs", "Polyhedra"}
)
export {
-- Methods/Functions
    "allSpanningTrees",
    "basisForFlowPolytope",
    "bipartiteQuiver",
    "chainQuiver",
    "dualFlowPolytope",
    "flowPolytope",
    "isTight",
    "incInverse",
    "isSemistable",
    "isStable",
    "isAcyclic",
    "isClosedUnderArrows",
    "makeTight",
    "maximalUnstableSubquivers",
    "mergeOnVertex",
    "mergeOnArrow",
    "neighborliness",
    "stableTrees",
    "subquivers",
    "sameChamber",
    "theta",
    "threeVertexQuiver",
    "walls",
    "wallType",
-- Options
    "AsSubquiver",
    "Axis",
    "EdgesAdded",
    "Flow",
    "MatrixType",
    "MaxSum",
    "MinSum",
    "Oriented",
    "Output",
    "RavelLoops",
    "Replacement",
    "SavePath",
-- Quiver objects 
    "ToricQuiver",
    "toricQuiver"
}
protect connectivityMatrix
protect flow
protect NonSingletons
protect Q0
protect Q1
protect Qplus
protect Singletons
protect WallType
protect weights

ToricQuiver = new Type of HashTable
Wall = new Type of HashTable
toricQuiver = method(Options=>{Flow=>"Default"})

FlowCeil := 100;

-- construct ToricQuiver from connectivity matrix
toricQuiver(Matrix) := opts -> Q -> (
    F := 0.5*sumList(for x in entries(Q) list(for y in x list(abs(y))), Axis=>"Col");
    if opts.Flow == "Canonical" then (
        F = asList(numColumns(Q):1);
    ) else if opts.Flow == "Random" then (
        F = for i in (0..#F - 1) list(random(FlowCeil));
    );
    -- set Q to be unit valued to apply flow
    Q = matrix(for e in entries(Q) list(for x in e list(if abs(x) > 0 then x/abs(x) else 0)));
    new ToricQuiver from hashTable{
        connectivityMatrix=>Q,
        Q0=>toList(0..numRows(Q) - 1),
        Q1=>graphEdges(Q, Oriented=>true),
        flow=>F,
        weights=>sumList(entries(Q*diagonalMatrix(F)), Axis=>"Row")
    }
)


-- construct ToricQuiver from connectivity matrix and a flow
toricQuiver(Matrix, List) := opts -> (Q, F) -> (
    -- set Q to be unit valued to apply flow
    Q = matrix(for e in entries(Q) list(for x in e list(if abs(x) > 0 then x/abs(x) else 0)));
    new ToricQuiver from hashTable{
        connectivityMatrix=>Q,
        Q0=>toList(0..numRows(Q) - 1),
        Q1=>graphEdges(Q, Oriented=>true),
        flow=>asList(F),
        weights=>sumList(entries(Q*diagonalMatrix(F)), Axis=>"Row")
    }
)

toricQuiver(ToricQuiver) := opts -> Q -> (
    toricQuiver(Q.connectivityMatrix, Q.flow, Flow=>opts.Flow)
)

toricQuiver(ToricQuiver, List) := opts -> (Q, F) -> (
    toricQuiver(Q.connectivityMatrix, F)
)

-- construct ToricQuiver from list of edges
toricQuiver(List) := opts -> E -> (
    Q := graphFromEdges(E, Oriented=>true);
    F := asList(#E:1);
    if opts.Flow == "Random" then (
        F = for i in (0..#E - 1) list(random(FlowCeil));
    );
    new ToricQuiver from hashTable{
        connectivityMatrix=>Q,
        Q0=>asList(0..numRows(Q) - 1),
        Q1=>E,
        flow=>F,
        weights=>sumList(entries(Q*diagonalMatrix(F)), Axis=>"Row")
    }
)

-- construct ToricQuiver from list of edges and a flow
toricQuiver(List, List) := opts -> (E, F) -> (
    Q := graphFromEdges(E, Oriented=>true);
    new ToricQuiver from hashTable{
        connectivityMatrix=>Q,
        Q0=>toList(0..numRows(Q) - 1),
        Q1=>E,
        flow=>F,
        weights=>sumList(entries(Q*diagonalMatrix(F)), Axis=>"Row")
    }
)
-- construct ToricQuiver from a Graph object
toricQuiver(Graph) := opts -> G -> (
    E := for e in edges(G) list toList(e);
    toricQuiver(E, Flow=>opts.Flow)
)

toricQuiver(Graph, List) := opts -> (G, F) -> (
    E := for e in edges(G) list toList(e);
    toricQuiver(E, F)
)

-- subquiver of a ToricQuiver by taking a subset of the arrows, represented as a "child" of the original quiver
ToricQuiver ^ List := (TQ, L) -> (
    newFlow := TQ.flow;
    Lc := asList(set(0..#TQ.flow - 1) - set(L));
    for i in Lc do(newFlow = replaceInList(i, 0, newFlow));
    toricQuiver(TQ.connectivityMatrix, newFlow)
)
-- subquiver of a ToricQuiver by removing all vertices/arrows not in the subquiver
ToricQuiver _ List := (TQ, L) -> (
    M := matrix(for x in entries(TQ.connectivityMatrix_L) list(if any(x, y-> y != 0) then (x) else (continue;)));
    toricQuiver(M)
)
-- equality of two quivers:
ToricQuiver == ToricQuiver := (TQ1, TQ2) -> (
    TQ1i := sortedIndices(TQ1.Q1);
    TQ2i := sortedIndices(TQ2.Q1);
    (sort(TQ1.Q1) === sort(TQ2.Q1)) and (TQ1.flow_TQ1i == TQ2.flow_TQ2i)
)
------------------------------------------------------------


------------------------------------------------------------
adjacencyToConnectivity = (A) -> (
    E := for i in (0..numRows(A) - 1) list(for j in (0..numColumns(A) - 1) list(if A_{j}^{i} != 0 then (i, j)));
    matrix(graphFromEdges(E), Oriented=>true)

)
------------------------------------------------------------


------------------------------------------------------------
asList = x -> (
    if instance(x, List) then(
        return x
    )
    else if instance(x, Sequence) then(
        return toList(x)
    )
    else if instance(x, Set) then(
        return toList(x)
    )
    else
        return {x}
)
------------------------------------------------------------


------------------------------------------------------------
-- add all elements of a list x together, and specify Axis (row/col) if x is actually a matrix or list of lists -- 
sumList = {Axis=>"None"} >> opts -> x -> (
    s := 0;
    if opts.Axis == "Row" then (
        s = flatten(for i in x list(sumList(i)));
    )
    else if opts.Axis == "Col" then (
       pivoted := entries(transpose(matrix(x)));
       s = flatten(for i in pivoted list(sumList(i)));
    )
    else (
        s = sum(asList(x));
    );
    return s
)
------------------------------------------------------------


------------------------------------------------------------
incInverse = (tQ, th) -> (
    a := tQ.connectivityMatrix;
    a = a * diagonalMatrix(for t in tQ.flow list floor t);
    b := matrix(for t in th list {floor t}) **QQ;
    F := solve(a **QQ, b);
    flatten entries first asList F
)
------------------------------------------------------------


------------------------------------------------------------
-- take all possible combinations of length k from list l -- 
-- optional arguments: 
-- -- Replacement(true/false) = with replacement
-- -- MinSum(numeric value) = exclude all combinations with sum below MinSum
-- -- MaxSum(numeric value) = exclude all combinations with sum above MaxSum
-- -- Order(true/false) = whether or not the ordering of combination values matters
combinations = {Replacement=>true, MinSum=>-1000, MaxSum=>-1000, Order=>true} >> opts -> (k, l) -> (
    combs := {};
    combs1 := {};
    combs2 := {};
    if k > 1 then (
        -- if we are using combinations with replacement -- 
        if opts.Replacement then (
           combs = flatten(join(for i in l list(for j from 0 to k - 1 list(i))));
           combs1 = unique(subsets(combs, k));
           combs2 = unique(subsets(combs, k));
           for i in combs2 do (combs1 = append(combs1, reverse(i)));
        )
        else (
           combs = flatten(for i in l list(i));
           combs1 = unique(subsets(combs, k));
           combs2 = unique(subsets(combs, k));
           for i in combs2 do (combs1 = append(combs1, reverse(i)));
        );
    )
    else combs1 = for i in l list(asList(i));

    -- if we are using restricting either by a minimum or maximum sum -- 
    if opts.MinSum != -1000 then (
       combs1 = for i in combs1 list(if sumList(i) < opts.MinSum then (continue;) else (i));
    );
    if opts.MaxSum != -1000 then (
       combs1 = for i in combs1 list(if sumList(i) > opts.MaxSum then (continue;) else (i));
    );

    if opts.Order != true then (
        combs = unique(
            for i in combs1 list(sort(i))
        );
    ) else (
        combs = unique(flatten for c in combs1 list permutations(c));
    );
    combs
)
------------------------------------------------------------


------------------------------------------------------------
-- return the indices of the list l in order the values occur 
-- in the sorted list sort(l)
sortedIndices = (l) -> (
    sortedVals := unique(sort(l));
    flatten(for i in sortedVals list(positions(l, x -> x == i)))
)
------------------------------------------------------------


------------------------------------------------------------
replaceInList = (i, v, l) -> (
    insert(i, v, drop(l, {i,i}))
)
------------------------------------------------------------


------------------------------------------------------------
isPermutation = (x, y) -> (
    toRet := false;

    xrows := entries(x);
    yrows := sort(entries(y));
    xcols := entries(transpose(x));
    ycols := entries(transpose(y));

    if #xrows == #yrows and #xcols == #ycols then (
        rs := toList(0..#xrows - 1);
        -- rowPermutations = permutations(rs);
        for rPerm in permutations(rs) do (
            if xrows_rPerm == yrows then (
                toRet = true;
                break;
            )
            else (
                xrowsP := matrix(xrows_rPerm);
                cs := toList(0..#xcols - 1);
                -- colPermutations := permutations(cs);
                for cPerm in permutations(cs) do (
                    if entries(xrowsP_cPerm) == yrows then (
                        toRet = true;
                        break;
                    );
                );
            );
        );
    );
    toRet
)
------------------------------------------------------------


------------------------------------------------------------
-- yield the edges of a graph in the form of a list of pairs 
-- (v1, v2), where edge E is from v1 to v2
graphEdges = method(Options=>{Oriented=>false, RavelLoops=>false});
graphEdges Matrix := opts -> (G) -> (
    E := {};
    if opts.Oriented == true then (
        E = for e in entries(transpose(G)) list(
            {position(e, i -> i < 0), 
             position(e, i -> i > 0)}
        );
    )
    else (
        E = for e in entries(transpose(G)) list(
            positions(e, i -> (i > 0 or i < 0))
        );
        if opts.RavelLoops == true then (
            E = for e in E list(if #e > 1 then e else toList(2:e#0));
        );
    );
    return E
)
graphEdges ToricQuiver := opts -> (G) -> (
    graphEdges(G.connectivityMatrix, Oriented=>opts.Oriented, RavelLoops=>opts.RavelLoops)
)
------------------------------------------------------------


------------------------------------------------------------
-- yield the matrix rep of graph, given a list of edges as ordered 
-- pairs (this is the opposite of graphEdges() function. 
graphFromEdges = {Oriented=>false} >> opts -> E -> (
    -- first, if oriented graph, then make sure this is reflected. 
    tailVal := 1;
    if opts.Oriented == true then (
        tailVal = -1;
    );

    nVerts := max(flatten(E))+1;
    cols := for i in E list(
        row := (nVerts:0);
        asList(replaceInList(i#0, tailVal, replaceInList(i#1, 1, row)))
    );
    transpose(matrix(cols))
)
------------------------------------------------------------


------------------------------------------------------------
edgesOutOfPoint = {Oriented=>false} >> opts -> (p, E) -> (
    if opts.Oriented then (
        for i from 0 to #E - 1 list(e := E#i; if p != e#0 then (continue;) else (i, e))
    )
    else (
        for i from 0 to #E - 1 list(e := E#i; if (#positions(e, j -> j == p) < 1) then (continue;) else (i, e))
    )
)
------------------------------------------------------------


------------------------------------------------------------
-- check if graph is connected
isGraphConnected = G -> (
    gEdges := graphEdges(G, Oriented=>false);
    lens := sortedIndices(for e in gEdges list(-#e));
    gEdges = gEdges_lens;

    if max(for e in gEdges list(#e)) > 1 then (
        isConnected(graph(gEdges))
    )
    else (
        if max(flatten(gEdges)) < 1 then (
            true
        )
        else (
            false
        )
    )
)
------------------------------------------------------------


------------------------------------------------------------
-- DFS search to find cycle in directed graph:
findCycleDFS = (startV, visited, E) -> (
    retVal := false;
    edgesOut := edgesOutOfPoint(startV, E, Oriented=>true);
    for edge in edgesOut do (
        currentVisited := asList(visited);
        edgeVerts := edge#1;
        endV := edgeVerts#1;
        if visited#endV == 1 then (
            retVal = true;
            break;
        );
        if retVal then break;
        currentVisited = replaceInList(endV, 1, visited);
        retVal = findCycleDFS(endV, currentVisited, E);
    );
    retVal
)
------------------------------------------------------------


------------------------------------------------------------
-- check if there exists a cycle in a (possibly unconnected)
-- oriented graph, passed in matrix form. 
existsOrientedCycle = (G) -> (
    retVal := false;
    E := graphEdges(G, Oriented=>true);
    V := asList(0..numRows(G)-1);
    for firstV in V do (
        visited := replaceInList(firstV, 1, asList(#V:0));
        result := findCycleDFS(firstV, visited, E);
        if result then (
            retVal = true;
            break;
        )
    );
    retVal
)
------------------------------------------------------------


------------------------------------------------------------
existsUnorientedCycle = (G) -> (
    retVal := false;
    E := graphEdges(G, Oriented=>false);
    for i from 0 to #E - 1 do (
        if isEdgeInCycle(i, E) then (
            retVal = true;
            break;
        );
    );
    retVal
)
------------------------------------------------------------


------------------------------------------------------------
isAcyclic = method()
isAcyclic(Matrix) := Q -> (
    not existsOrientedCycle(Q)
)
isAcyclic(ToricQuiver) := Q -> (
    not existsOrientedCycle(Q.connectivityMatrix)
)
------------------------------------------------------------


------------------------------------------------------------
-- check if there exists a path between p and q by appending 
-- edges in E(which is a list of pairs (v1, v2). 
-- optional arguments: 
-- -- Oriented(true/false) = whether or not the graph should be oriented
-- -- SavePath(true/false) = whether or not to return the edges involved in the path
-- -- EdgesAdded(list) = internal mechanism for computing for SavePath

------------------------------------------------------------
isPathBetween = {Oriented=>false, SavePath=>false, EdgesAdded=>{}} >> opts -> (p, q, E) -> (
    ifPath := false;
    existsPath := false;
    currentEdges := {};
    pathsToSee := edgesOutOfPoint(p, E, Oriented=>opts.Oriented);

    for edge in pathsToSee do (
        --- get the edge index and enpoints
        i := edge#0;
        e := edge#1;
        v := e#1;
        if p == e#1 then (
            v = e#0;
        );
        if opts.SavePath then (
            currentEdges = append(toList(opts.EdgesAdded), {p, v});
        );

        if q == v then (
            existsPath = true;
            break;
        )
        else (
            thisPath := {};
            remainingEdges := for j from 0 to #E - 1 list(if j == i then (continue;) else E#j);

            if opts.SavePath then (
                (ifPath, thisPath) = isPathBetween(v, q, remainingEdges, Oriented=>opts.Oriented, SavePath=>true, EdgesAdded=>currentEdges);
            )
            else (
                ifPath = isPathBetween(v, q, remainingEdges, Oriented=>opts.Oriented, EdgesAdded=>currentEdges);
            );
            if ifPath then (
                existsPath = true;
                currentEdges = currentEdges | thisPath;
                break;
            );
        );
    );
    if opts.SavePath then (
        return (existsPath, currentEdges);
    )
    else (
        return existsPath;
    )
)
------------------------------------------------------------


------------------------------------------------------------
-- checks if there is a cycle containing given edge. 
isEdgeInCycle = (i, E) -> (
    if #E > 1 then (
        e := E#i;
        if #e > 1 then (
            p := e#0;
            q := e#1;
        )
        else (
            p = e#0;
            q = e#0;
        );
        indicesToSave := drop(toList(0..(#E-1)), {i,i});
        isPathBetween(p, q, E_indicesToSave)
    )
    else (
        false
    )
)
------------------------------------------------------------


------------------------------------------------------------
splitLoops = m -> (
    Es := graphEdges(m, Oriented=>false);
    nVerts := numRows(m);
    loopsBroken := for i from 0 to #Es - 1 list(
        e := Es#i;
        if (#e < 2) or #(delete(e#0, e)) < 1 then (
            i
        )
        else (continue;)
    );
    altLB := flatten(for i in loopsBroken list(i));
    newEdges := flatten(for i from 0 to #Es - 1 list (
        e := Es#i;
        if #loopsBroken != #delete(i, loopsBroken) then (
            p := position(loopsBroken, x -> x == i);
            altLB = append(replaceInList(p, loopsBroken_p + p, altLB), loopsBroken_p + p + 1);
            {{e#0, nVerts+p}, {nVerts+p, e#0}}
        )
        else (
            {e}
        )
    ));
    (graphFromEdges(newEdges), altLB)
)
------------------------------------------------------------


------------------------------------------------------------
splitEdges = (m, E) -> (
    Es := graphEdges(m, Oriented=>false);
    nVerts := numRows(m);

    for i from 0 to #E - 1 do (
        ei := E#i;
        e := Es#ei;
        Es = append(replace(i, {e#0, nVerts+i}, Es), {nVerts+i, e#1});
    );
    graphFromEdges(Es)
)
------------------------------------------------------------


------------------------------------------------------------
bipartiteQuiver = {Flow=>"Canonical"} >> opts -> (a, b) -> (
    if instance(opts.Flow, List) then (
        if #opts.Flow != a*b then (
            print("error: provided flow is not correct length.");
            return;
        );
        toricQuiver(flatten(for ai from 0 to a - 1 list(for bi from 0 to b - 1 list({ai, a+bi}))), opts.Flow)
    ) else (
        toricQuiver(flatten(for ai from 0 to a - 1 list(for bi from 0 to b - 1 list({ai, a+bi}))), Flow=>opts.Flow)
    )
)
------------------------------------------------------------


------------------------------------------------------------
chainQuiver = {Flow=>"Canonical"} >> opts -> (numEdges) -> (
    Es := flatten for v from 0 to #numEdges - 1 list(
        numEs := numEdges#v;
        for j from 1 to numEs list({v, v+1})
    );
    if instance(opts.Flow, List) then (
        if #opts.Flow != sum(numEdges) then (
            print("error: provided flow is not correct length.");
            return;
        );
        return toricQuiver(Es, opts.Flow)
    ) else (
        return toricQuiver(Es, Flow=>opts.Flow)
    )
)
------------------------------------------------------------


------------------------------------------------------------
threeVertexQuiver = {Flow=>"Canonical"} >> opts -> (numEdges) -> (
    if #numEdges != 3 then (
        print("error: need a list of 3 numbers, denoting the number of edges between each pair of vertices");
        return;
    );
    Es0 := for i from 0 to numEdges#0 - 1 list({0, 1});
    Es1 := for i from 0 to numEdges#1 - 1 list({1, 2});
    Es2 := for i from 0 to numEdges#2 - 1 list({0, 2});
    Es := Es0 | Es2 | Es1;

    if instance(opts.Flow, List) then (
        if #opts.Flow != sum(numEdges) then (
            print("error: provided flow is not correct length.");
            return;
        );
        return toricQuiver(Es, opts.Flow)
    ) else (
        return toricQuiver(Es, Flow=>opts.Flow)
    )
)
------------------------------------------------------------


------------------------------------------------------------
-- yield the subquivers of a given quiver Q
subquivers = method(Options=>{Format=>"quiver", AsSubquiver=>false})
subquivers Matrix := opts -> Q -> (
    numArrows := numColumns(Q);
    arrows := 0..(numArrows - 1);
    QFlow := 0.5*sumList(for x in entries(Q) list(for y in x list(abs(y))), Axis=>"Col");

    flatten(
        for i from 1 to numArrows - 1 list (
            for c in combinations(i, arrows, Order=>false, Replacement=>false) list (
                if opts.Format == "list" then (
                    c
                ) else (
                    if opts.AsSubquiver then (
                        toricQuiver(Q, QFlow)^c
                    ) else (
                        toricQuiver(Q)_c
                    )
                )
            )
        )
    )
)
subquivers ToricQuiver := opts -> Q -> (
    numArrows := #Q.Q1;
    arrows := 0..(numArrows - 1);

    flatten(
        for i from 1 to numArrows - 1 list (
            for c in combinations(i, arrows, Order=>false, Replacement=>false) list (
                if opts.Format == "list" then (
                    c
                ) else (
                    if opts.AsSubquiver then (
                        Q^c
                    ) else (
                        Q_c
                    )
                )
            )
        )
    )
)
------------------------------------------------------------


------------------------------------------------------------
isClosedUnderArrows = method()
isClosedUnderArrows (Matrix, List) := (Q, V) -> (
    Qt := transpose(Q);
    sQ := entries(Qt_V);
    all(sumList(sQ, Axis=>"Row"), x -> x >=0)
)
isClosedUnderArrows (List, Matrix) := (V, Q) -> (
    isClosedUnderArrows(Q, V)
)
isClosedUnderArrows (List, ToricQuiver) := (V, Q) -> (
    isClosedUnderArrows(Q.connectivityMatrix, V)
)
isClosedUnderArrows (Matrix, ToricQuiver) := (SQ, Q) -> (
    SQM := entries transpose SQ;
    V := positions(SQM, x -> all(x, y-> y != 0));
    isClosedUnderArrows(Q.connectivityMatrix, V)
)
isClosedUnderArrows (ToricQuiver, ToricQuiver) := (SQ, Q) -> (
    SQM := entries (SQ.connectivityMatrix*diagonalMatrix(SQ.flow));
    V := positions(SQM, x -> any(x, y -> y != 0));
    isClosedUnderArrows(Q.connectivityMatrix, V)
)
------------------------------------------------------------


------------------------------------------------------------
-- list the subsets of a quiver Q that are closed under arrows
subsetsClosedUnderArrows = method()
subsetsClosedUnderArrows Matrix := (Q) -> (
    currentVertices := 0..(numRows(Q) - 1);

    flatten(for i from 1 to #currentVertices - 1 list(
        for c in combinations(i, currentVertices, Order=>false, Replacement=>false) list(
            if isClosedUnderArrows(c, Q) then (
                c
            )
            else(
                continue;
            )
        )
    ))
)
subsetsClosedUnderArrows ToricQuiver := (Q) -> (
    subsetsClosedUnderArrows(Q.connectivityMatrix)
)
------------------------------------------------------------


------------------------------------------------------------
-- return ordered list of the weights for the vertices of quiver Q
theta = method()
theta(ToricQuiver) := Q -> (
    Q.weights
)
theta(Matrix) := Q -> (
    sumList(entries(Q), Axis=>"Row")
)
------------------------------------------------------------


------------------------------------------------------------
isStable = method()
isStable(ToricQuiver, List) := (Q, subQ) -> (
    Qcm := Q.connectivityMatrix;

    -- get the vertices in the subquiver
    subQVertices := positions(entries(Qcm_subQ), x -> any(x, y -> y != 0));

    -- weights of the original quiver
    Qtheta := Q.weights;

    -- inherited weights on the subquiver
    weights := Qtheta_subQVertices;

    -- negative weights in Q_0 \ subQ_0
    otherVertices := asList(set(0..#Qtheta - 1) - set(subQVertices));
    minWeight := sum(apply({0} | asList(Qtheta_otherVertices), x -> if(x <= 0) then x else 0));

    subMat := Qcm_subQ;
    tSubMat := transpose(subMat);
    subMat = transpose(tSubMat_subQVertices);

    sums := asList(
        for subset in subsetsClosedUnderArrows(subMat) list(
            sumList(weights_subset)
        )
    );
    all(sums, x -> x + minWeight > 0)
)
isStable(ToricQuiver, ToricQuiver) := (Q, subQ) -> (
    nonZeroEntries := positions(subQ.flow, x -> (x > 0) or (x < 0));
    isStable(Q, nonZeroEntries)
)
------------------------------------------------------------


------------------------------------------------------------
isSemistable = method()
isSemistable(ToricQuiver, List) := (Q, subQ) -> (
    Qcm := Q.connectivityMatrix;

    -- get the vertices in the subquiver
    subQVertices := positions(entries(Qcm_subQ), x -> any(x, y -> y != 0));

    -- weights of the original quiver
    Qtheta := Q.weights;

    -- inherited weights on the subquiver
    weights := Qtheta_subQVertices;

    -- negative weights in Q_0 \ subQ_0
    otherVertices := asList(set(0..#Qtheta - 1) - set(subQVertices));
    minWeight := sum(apply({0} | asList(Qtheta_otherVertices), x -> if(x <= 0) then x else 0));

    subMat := Qcm_subQ;
    tSubMat := transpose(subMat);
    subMat = transpose(tSubMat_subQVertices);

    sums := asList(
        for subset in subsetsClosedUnderArrows(subMat) list(
            sumList(weights_subset)
        )
    );
    all(sums, x -> x + minWeight >= 0)
)
isSemistable(ToricQuiver, ToricQuiver) := (Q, subQ) -> (
    nonZeroEntries := positions(subQ.flow, x -> (x > 0) or (x < 0));
    isSemistable(Q, nonZeroEntries)
)
------------------------------------------------------------


------------------------------------------------------------
unstableSubquivers = method(Options=>{Format=>"list"})
unstableSubquivers(ToricQuiver) := opts -> Q -> (
    numArrows := #Q.Q1;
    arrows := asList(0..numArrows - 1);

    L := flatten(for i from 1 to numArrows - 1 list (
        combinations(numArrows - i, arrows, Replacement=>false, Order=>false) 
    ));

    sqsWithArrows := for sQ in L list(
        if not isStable(Q, asList(sQ)) then (
            if (opts.Format == "list") then (
                sQ
            ) else (
                Q^sQ
            )
        ) else (
            continue;
        )
    );
    singletonUnstableSqs := for x in positions(Q.weights, x -> x < 0) list ({x});

    hashTable({NonSingletons => sqsWithArrows, Singletons => singletonUnstableSqs})
)
------------------------------------------------------------


------------------------------------------------------------
isProperSubset = (Q1, Q2) -> (
    if set(Q1) === set(Q2) then (
        false
    ) else (
        isSubset(set(Q1), set(Q2))
    )
)
------------------------------------------------------------


------------------------------------------------------------
isMaximal = method()
isMaximal(Matrix, List) := (Q, Qlist) -> (
    returnVal := true;
    for Q2 in Qlist do (
        if isProperSubset(Q, Q2) then (
            returnVal = false;
        );
    );
    returnVal
)
isMaximal(ToricQuiver, List) := (Q, Qlist) -> (
    Ms := for Qm in Qlist list(Qm.connectivityMatrix);
    isMaximal(Q.connectivityMatrix, Ms)
)
------------------------------------------------------------


------------------------------------------------------------
maximalUnstableSubquivers = {Format=>"list"} >> opts -> (Q) -> (
    unstableList := unstableSubquivers(Q, Format=>"list");

    withArrows := for subQ1 in unstableList.NonSingletons list (
        IsMaximal := true;
        for subQ2 in unstableList#NonSingletons do (
            if isProperSubset(subQ1, subQ2) then (
                IsMaximal = false;
            );
        );
        if IsMaximal then (
            if (opts.Format == "list") then (
                subQ1
            ) else (
                Q^subQ1
            )
        ) else (
            continue;
        )
    );
    containedSingletons := flatten for subQ1 in unstableList#NonSingletons list (
        for x in Q.Q1_subQ1 list ({x})
    );
    withoutArrows := asList(set(unstableList#Singletons) - set(containedSingletons));

    hashTable {NonSingletons=>withArrows, Singletons=>withoutArrows}
)
------------------------------------------------------------


------------------------------------------------------------
isTight = method(Options=>{Format=>"Flow"})
isTight(ToricQuiver) := opts -> Q -> (
    numArrows := #Q#Q1;
    maxUnstSubs := maximalUnstableSubquivers(Q);
    if numArrows > 1 then (
        all(maxUnstSubs#NonSingletons, x -> #x != (numArrows - 1))
    ) else (
        #maxUnstSubs#Singletons < 1
    )
)
isTight(ToricQuiver, List) := opts -> (Q, F) -> (
    if opts.Format == "Flow" then (
        isTight(toricQuiver(Q.connectivityMatrix, F))
    ) else (
        FF := incInverse(Q, F);
        isTight(toricQuiver(Q.connectivityMatrix, FF))
    )
)
isTight(List, ToricQuiver) := opts -> (F, Q) -> (
    if opts.Format == "Flow" then (
        isTight(toricQuiver(Q.connectivityMatrix, F))
    ) else (
        FF := incInverse(Q, F);
        isTight(toricQuiver(Q.connectivityMatrix, FF))
    )
)
------------------------------------------------------------


------------------------------------------------------------
neighborliness = method()
neighborliness ToricQuiver := (Q) -> (
    numArrows := #Q.Q1;
    maxUnstables := maximalUnstableSubquivers(Q);
    maxUnstables = maxUnstables#NonSingletons;

    k := max(
        for sQ in maxUnstables list(
            numArrows - #sQ
        )
    );
    k
)
------------------------------------------------------------


------------------------------------------------------------
wallType = method()
wallType(Matrix, List) := (Q, Qp) -> (
    tp := sum(for x in sumList(Q^Qp, Axis=>"Col") list(if x < 0 then (1) else (continue;)));
    tm := sum(for x in sumList(Q^Qp, Axis=>"Col") list(if x > 0 then (1) else (continue;)));
    (tp, tm)
)
wallType(ToricQuiver, List) := (Q, Qp) -> (
    wallType(Q.connectivityMatrix*diagonalMatrix(Q.flow), Qp)
)
------------------------------------------------------------


------------------------------------------------------------
walls = method()
walls(Matrix) := (Q) -> (
    nv := numRows(Q);
    nvSet := set(0..nv - 1);
    subs := (1..ceiling(nv/2));

    Qms := flatten(for i from 1 to ceiling(nv/2) list (
        combinations(i, asList(nvSet), Replacement=>false, Order=>false)
    ));

    alreadyMet := set ();
    Qedges := graphEdges(Q, Oriented=>true);

    for Qm in Qms list(
        mSums := sumList(Q^Qm, Axis=>"Col");
        QmEdgeIndices := for s in (0..#mSums - 1) list(if (mSums_s == 0) then (s) else (continue;));
        Qp := asList(nvSet - set(Qm));

        if member(Qm, alreadyMet) then ( 
            continue;
        ) else if isGraphConnected(Q^Qm_QmEdgeIndices) then (
            alreadyMet = alreadyMet + set ({Qp}) + set ({Qm});
            pSums := sumList(Q^Qp, Axis=>"Col");
            QpEdgeIndices := for s in (0..#pSums - 1) list(if (pSums_s == 0) then (s) else (continue;));
            if (#Qp < 2) or (isGraphConnected(Q^Qp_QpEdgeIndices)) then (
               new Wall from hashTable ({Qplus=>Qp, WallType=>wallType(Q, Qp)})
            )
        )
    )
)
walls(ToricQuiver) := (Q) -> (
    walls(Q.connectivityMatrix*diagonalMatrix(Q.flow))
)
------------------------------------------------------------


------------------------------------------------------------
-- Returns a spanning tree(the first one that is encountered) of 
-- the quiver Q with |Q_1| - |Q_0| + 1 edges removed. 
-- NOTE: if such a spanning tree is not possible, then it returns empty lists
--
-- input: 
--     - Q: Matrix representation of quiver
-- outputs:
--     - edges_kept(list of tuples): list of the edges in the spanning tree
--     - edges_removed(list of tuples)): list of the edges in the complement of the spanning tree
--
spanningTree = (Q) -> (
    Q0 := numRows(Q);
    Q1 := numColumns(Q);

    --  edges of quiver Q represented as a list of tuples
    allEdges := graphEdges(Q, Oriented=>true);
    allNodes := asList(0..Q0-1);

    -- number of edges to remove from spanning tree
    d := Q1 - Q0 + 1;

    edgeIndices := {};
    if d > 0 then (
        dTuplesToRemove := combinations(d, asList(0..#allEdges-1), Replacement=>false, Order=>false);
        edgesKept := {};
        edgesRemoved := {};
        foundTree := false;

        for dTuple in dTuplesToRemove do (
            edgeIndices = asList(set(0..#allEdges - 1) - set(dTuple));
            edgesKept = allEdges_edgeIndices;
            edgesRemoved = allEdges_dTuple;

            reducedG := transpose(matrix(for e in edgesKept list(
                t := e#0;
                h := e#1;
                localE := asList(Q0:0);
                localE = replaceInList(h,  1, localE);
                localE = replaceInList(t, -1, localE);
                localE
            )));
            if numColumns(reducedG) > 1 then (
                notAnyCycles := not existsUnorientedCycle(reducedG);

                if isGraphConnected(reducedG) and notAnyCycles then (
                    foundTree = true;
                    break;
                );
            ) else (
                foundTree = true;
                break;
            );
        );
        if foundTree then (
            dTuple := asList(set(0..#allEdges - 1) - set(edgeIndices));
            return (edgeIndices, dTuple);
        ) else (
            return ({}, {});
        );
    ) else (
        return (allEdges, {});
    );
)
------------------------------------------------------------


------------------------------------------------------------
allSpanningTrees = (TQ) -> (
    Q := TQ.connectivityMatrix;
    Q0 := numRows(Q);
    Q1 := numColumns(Q);

    --  edges of quiver Q represented as a list of tuples
    allEdges := graphEdges(Q, Oriented=>true);
    allNodes := asList(0..Q0-1);

    trees := {};
    edgeIndices := {};
    
    -- in any tree, the number of edges should be #vertices - 1, 
    -- and so we need to remove Q1 - (Q0-1) edges to obtain a tree

    d := Q1 - Q0 + 1;
    if d > 0 then (
        dTuplesToRemove := combinations(d, asList(0..#allEdges-1), Replacement=>false, Order=>false);
        edgesKept := {};
        edgesRemoved := {};

        trees = for dTuple in dTuplesToRemove list (
            edgeIndices = asList(set(0..#allEdges - 1) - set(dTuple));
            edgesKept = allEdges_edgeIndices;
            edgesRemoved = allEdges_dTuple;

            reducedG := transpose(matrix(for e in edgesKept list(
                t := e#0;
                h := e#1;
                localE := asList(Q0:0);
                localE = replaceInList(h,  1, localE);
                localE = replaceInList(t, -1, localE);
                localE
            )));
            if numColumns(reducedG) > 1 then (
                notAnyCycles := not existsUnorientedCycle(reducedG);
                if isGraphConnected(reducedG) and notAnyCycles then (
                    edgeIndices
                ) else ( 
                    continue;
                )
            ) else (
                edgeIndices
            )
        );
    );
    trees
)
------------------------------------------------------------

------------------------------------------------------------
-- this function lists all of the spanning trees T of TQ
-- such that T admits a regular flow in the preimage of weight th
stableTrees = (th, TQ) -> (
    allTrees := allSpanningTrees(TQ);
    for x in allTrees list(if all(incInverse(TQ_x, th), y -> y > 0) then (x) else continue )
)
------------------------------------------------------------

------------------------------------------------------------
-- this function checks if the weights theta1 and theta2 
-- belong to the same chamber in the wall chamber decomposition for Q
sameChamber = (theta1, theta2, Q) -> (
    treesTheta1 := stableTrees(theta1, Q);
    treesTheta2 := stableTrees(theta2, Q);
    return all(0..#treesTheta1 - 1, x -> treesTheta1#x == treesTheta2#x)
)
------------------------------------------------------------


------------------------------------------------------------
isIn = (v, l) -> (
    p := positions(l, x -> x == v);
    #p > 0
)
------------------------------------------------------------


------------------------------------------------------------
-- gives the edges that comprise an undirected cycle in the graph G, 
-- (which is assumed to contain a single cycle) and returns the ordered cycle

--  input: G(list of tuples): edges of graph G
--  output: cycle(list of tuples): tuple representation of the edges contained in the cycle
primalUndirectedCycle = (G) -> (
    if existsUnorientedCycle(graphFromEdges(G)) then (
        for i from 0 to #G - 1 do (
            edge := G#i;
            (isCycle, cycle) := isPathBetween(edge#1, edge#0, drop(G, {i, i}), 
                                              Oriented=>false, SavePath=>true, EdgesAdded=>{edge});
            if isCycle then (
                edgeIndices := {};
                metEdges := {};

                for cE in cycle do (
                    for gI in asList(0..#G - 1) do (
                        if isIn(gI, metEdges) then (
                            continue;
                        ) else (
                            gE := G#gI;
                            if (gE#0 == cE#0) and (gE#1 == cE#1) then (
                                metEdges = metEdges | {gI};
                                edgeIndices = edgeIndices | {gI};
                                break;
                            ) else if (gE#1 == cE#0) and (gE#0 == cE#1) then (
                                metEdges = metEdges | {gI};
                                edgeIndices = edgeIndices | {-(gI+1)};
                                break;
                            );
                        );
                    );
                );
                return edgeIndices;
            );
        );
        return {};
    ) else (
        return G;
    );
)
------------------------------------------------------------


------------------------------------------------------------
makeTight = (Q, W) -> (
    potentialF := incInverse(Q, W);
    k := entries generators kernel Q.connectivityMatrix;
    potentialF = potentialF + flatten entries first asList(transpose(matrix({sumList(k, Axis=>"Row")})));


    if isTight(Q, potentialF) then (
        return toricQuiver(Q.connectivityMatrix, potentialF);
    ) else (
        if (#stableTrees(W, Q) < 1) then (
            print("Error: provided weight theta is not in C(Q) and so does not admit a tight toric quiver");
            return ;
        );

        Qcm := graphFromEdges(Q.Q1, Oriented=>true)*diagonalMatrix(potentialF);
        maxUnstSubs := maximalUnstableSubquivers(toricQuiver(Q.connectivityMatrix, potentialF));
        R := first(maxUnstSubs#NonSingletons);
        Rvertices := asList set flatten Q.Q1_R;
        S := {};

        if #R < 1 then (
            Rvertices = first(maxUnstSubs#Singletons);
            S = Rvertices;
        ) else (
            success := false;
            for i from 1 to #Rvertices - 1 do (
                combs := combinations(#Rvertices - i, Rvertices, Replacement=>false, Order=>false);
                for c in combs do (
                    if sumList(W_c) <= 0 then (
                        if isClosedUnderArrows(c, Q_R) then (
                            success = true;
                            S = c;
                            break;
                        );
                    );
                    if success then break;
                );
                if success then break;
            );
        );
        alpha := first toList (set(0..#Q.Q1-1) - set(R));
        a := sort(Q.Q1_alpha);
        {aMinus, aPlus} := (a_0, a_1);

        newRows := entries(Q.connectivityMatrix);
        newCols := drop(asList(0..#Q.Q1 - 1), {alpha, alpha});
        newM := matrix(for e in Q.Q0 list(
            if e == aMinus then (
                nRs := sumList(Q.connectivityMatrix^{aPlus, aMinus}, Axis=>"Col");
                nRs_newCols
            ) else if e == aPlus then (
                continue;
            ) else (
                nR := newRows_e;
                nR_newCols
            )
        ));
        newFlow := drop(potentialF, {alpha, alpha});
        newQ := toricQuiver(newM);
        newW := theta(newQ.connectivityMatrix*diagonalMatrix(newFlow));

	nonEmptyEdges := for i in 0..#newQ.Q1 - 1 list (
		e := newQ.Q1#i;
		if toString e#0 == "null" then (
			continue;
		) else (
			i
		)
	);
        return makeTight(newQ_nonEmptyEdges, newW);
    );
)
------------------------------------------------------------


basisForFlowPolytope = (Q) -> (
   (sT, removedEdges) := spanningTree(Q.connectivityMatrix);
    es := sT | removedEdges;

    f := for i from 0 to #removedEdges - 1 list(
        edge := Q.Q1_removedEdges#i;
        cycle := primalUndirectedCycle(Q.Q1_sT | {edge});

        cycle = for x in cycle list(
            if x == #sT then (x+i) else if x == -(#sT + 1) then (-#sT - i - 1) else (x)
        );

        fi := #es:0;
        for j in cycle do (
            if j >= 0 then (
                fi = replaceInList(j, 1, fi)
            ) else (
                k := -(1 + j);
                fi = replaceInList(k, -1, fi)
            );
        );
        fi
    );
    output := for j from 0 to #es - 1 list(
        for i from 0 to #removedEdges - 1 list(
            ff := f#i;
            ff#j
        )
    );
    transpose matrix output
)
------------------------------------------------------------
flowPolytope = method()
------------------------------------------------------------
flowPolytope(ToricQuiver, List) := (Q, th) -> (
    allTrees := allSpanningTrees(Q);
    regularFlows := for x in allTrees list(
        if all(incInverse(Q_x, th), y -> y >= 0) then (
            incInverse(Q^x, th)
        ) else (
            continue;
        )
    );
    vertices convexHull matrix regularFlows
)
------------------------------------------------------------
flowPolytope ToricQuiver := Q -> (
    flowPolytope(Q, Q.weights)
)
------------------------------------------------------------


------------------------------------------------------------
dualFlowPolytope = method()
------------------------------------------------------------
dualFlowPolytope(ToricQuiver) := (Q) -> (
    vertices polar convexHull flowPolytope(Q)
)
------------------------------------------------------------
dualFlowPolytope(ToricQuiver, List) := (Q, F) -> (
    vertices polar convexHull flowPolytope(Q, F)
)
------------------------------------------------------------


------------------------------------------------------------
mergeOnVertex = method()
mergeOnVertex(Matrix, ZZ, Matrix, ZZ) := (Q1, v1, Q2, v2) -> (
    nrow := numRows(Q1) + numRows(Q2) - 1;
    ncol := numColumns(Q1) + numColumns(Q2);
    Q1rs := numRows(Q1);
    Q1cs := numColumns(Q1);
    Q2cs := numColumns(Q2);

    i1 := asList(join(drop(0..numRows(Q1) - 1, {v1, v1}), {v1}));
    i2 := asList(join({v2}, drop(0..numRows(Q2) - 1, {v2, v2})));

    Q1 = entries(Q1^i1);
    Q2 = entries(Q2^i2);

    paddingSize := ncol - Q1cs;
    r := 0;
    matrix(
        for row in (0..nrow - 1) list(
            if row < (Q1rs - 1) then (
                Q1_row | asList(paddingSize:0)
            ) else if (row < Q1rs) then (
                Q1_row | Q2_0
            ) else (
                r = row - (Q1rs - 1);
                paddingSize = ncol - Q2cs;
                asList(paddingSize:0) | Q2_r 
            )
        )
    )
)
mergeOnVertex(ToricQuiver, ZZ, Matrix, ZZ) := (Q1, v1, Q2, v2) -> (
    mergeOnVertex(Q1.connectivityMatrix, v1, Q2, v2)
)
mergeOnVertex(Matrix, ZZ, ToricQuiver, ZZ) := (Q1, v1, Q2, v2) -> (
    mergeOnVertex(Q1, v1, Q2.connectivityMatrix, v2)
)
mergeOnVertex(ToricQuiver, ZZ, ToricQuiver, ZZ) := (Q1, v1, Q2, v2) -> (
    mergeOnVertex(Q1.connectivityMatrix, v1, Q2.connectivityMatrix, v2)
)
------------------------------------------------------------


------------------------------------------------------------
mergeOnArrow = method()
mergeOnArrow(Matrix, ZZ, Matrix, ZZ) := (Q1, a1, Q2, a2) -> (
    Q1nr := numRows(Q1);
    Q2nr := numRows(Q2);
    Q1nc := numColumns(Q1);
    Q2nc := numColumns(Q2);
    nrow := Q1nr + Q2nr - 2;
    ncol := Q1nc + Q2nc - 1;

    q1E := asList(graphEdges(Q1, Oriented=>true))_a1;
    q2E := asList(graphEdges(Q2, Oriented=>true))_a2;

    c1 := asList(join(drop(0..Q1nc - 1, {a1, a1}), {a1}));
    c2 := asList(drop(0..Q2nc - 1, {a2, a2}));

    r1 := asList(join(asList(set(0..Q1nr - 1) - set(q1E)), q1E));
    r2 := asList(join(q2E, asList(set(0..Q2nr - 1) - set(q2E))));

    Q1 = entries(Q1^r1)_c1;
    Q2 = entries(Q2^r2)_c2;

    paddingSize := 0;
    matrix(
        for row from 0 to nrow - 1 list(
            if row < (Q1nr - 2) then (
                paddingSize = Q2nc - 1;
                join(Q1_row, asList(paddingSize:0))

            ) else if row < Q1nr then (
                join(Q1_row, Q2_(2 + row - Q1nr))
            ) else (
                j := (row - Q1nr) + 2;
                paddingSize = Q1nc;
                asList(join(paddingSize:0, Q2_j))
            )
        )
    )
)
mergeOnArrow(ToricQuiver, ZZ, Matrix, ZZ) := (Q1, a1, Q2, a2) -> (
    mergeOnArrow(Q1.connectivityMatrix, a1, Q2, a2)
)
mergeOnArrow(Matrix, ZZ, ToricQuiver, ZZ) := (Q1, a1, Q2, a2) -> (
    mergeOnArrow(Q1, a1, Q2.connectivityMatrix, a2)
)
mergeOnArrow(ToricQuiver, ZZ, ToricQuiver, ZZ) := (Q1, a1, Q2, a2) -> (
    mergeOnArrow(Q1.connectivityMatrix, a1, Q2.connectivityMatrix, a2)
)
------------------------------------------------------------

beginDocumentation()
multidoc ///
    Node
        Key 
            ThinSincereQuivers
        Headline
            creating and manipulating Toric Quivers
        Description
            Text
                {\em ThinSincereQuivers} is a package for creating and manipulating toric quivers.
            Text   
                For further details in the theory, we suggest the following articles and the references within them:
            Text
                @UL { 
                      {"Lutz Hille, ", HREF{"https://doi.org/10.1016/S0024-3795(02)00406-8", EM "Quivers, cones and polytopes, "}, "
                       Linear algebra and its applications 365 (2003): 215-237."},
                      {"Mátyás Domokos and  Dániel Joó, ", HREF{"https://arxiv.org/abs/1402.5096v1", 
                            EM "On the equations and classification of toric quiver varieties"},",  
                          Proceedings. Section A, Mathematics-The Royal Society of Edinburgh 146.2 (2016): 265."
                    }
                }@
            Text
                @SUBSECTION "Menu"@
            Text
                @UL {
                    {TO "toric quiver representation"},
                    {TO "subquiver representation"},
                    -- {TO "toricQuiver"},
                    -- {TO "flowPolytope"},
                    -- {TO "dualFlowPolytope"},
                }@
    Node
        Key
            ToricQuiver
        Headline
            the ToricQuiver datatype
        Description
            Text
                The ToricQuiver data type is a type of Hash Table with the following keys: 
            Text
                @UL {
                    {TT "connectivityMatrix:", "matrix representation of the connected graph underlying the quiver"},
                    {TT "flow:              ", "list of integers representing the flow associated to each edge of the quiver"},
                    {TT "Q0:                ", "the list of vertices"},
                    {TT "Q1:                ", "the list of edges "},
                    {TT "weights:           ", "the values on each vertex induced by the flow"},
                }@
        SeeAlso
            "toricQuiver"
            "bipartiteQuiver"
            "threeVertexQuiver"
            "chainQuiver"

    Node
        Key
            toricQuiver
        Headline
            the toricQuiver constructor
        Usage
            Q = toricQuiver M
            Q = toricQuiver T
            Q = toricQuiver E
            Q = toricQuiver G
            Q = toricQuiver (M, F)
            Q = toricQuiver (T, F)
            Q = toricQuiver (E, F)
            Q = toricQuiver (G, F)
        Inputs
            M: Matrix 
                of integers giving the connectivity structure of the quiver
            T: ToricQuiver 
            F: List 
                the flow on the quiver given as a list of integers
            E: List
                of pairs {\tt (V1, V2)} giving the edges of the quiver in terms of the vertices
            G: Graph
            Flow => String
                that specifies the flow for the polytope
        Outputs
            Q: ToricQuiver
        Description
            Text
                A toric quiver is a directed graph {\tt Q=(Q_0, Q_1) } where 
                {\tt Q_0} is the set of vertices associated to {\tt Q} and {\tt Q_1} is the set of arrows. 
                Also included in $Q$ is a flow, which associates an integer value to each edge. 
                The canonical flow gives a weight of 1 to each edge. 
            Text
                the ToricQuiver data type is stored as a hash table with the following keys: 
            Text
                @UL {
                    {TT "connectivityMatrix:", "matrix representation of the connected graph underlying the quiver"},
                    {TT "flow:              ", "list of integers representing the flow associated to each edge of the quiver"},
                    {TT "Q0:                ", "the list of vertices"},
                    {TT "Q1:                ", "the list of edges "},
                    {TT "weights:           ", "the values on each vertex induced by the flow"},
                }@

            Example
                Q = toricQuiver matrix({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}})
                Q = toricQuiver(matrix({{-3,-1,-4,-1},{3,1,0,0},{0,0,4,1}}))
                Q = toricQuiver(matrix({{-3,-1,-4,-1},{3,1,0,0},{0,0,4,1}}), Flow=>"Canonical")
                Q = toricQuiver(matrix({{-1,-1,-1,-1},{0,0,1,1},{1,1,0,0}}), Flow=>"Random")
                Q = toricQuiver {{0,1},{0,1},{0,2},{0,2}}
        SeeAlso
            "bipartiteQuiver"
    Node
        Key
            (toricQuiver, Matrix)
        Headline
            make a toric quiver from a connectivity matrix
        Usage
            toricQuiver M
        Inputs
            M: Matrix
                of integers; each column corresponds to an arrow and each row
            Flow => String
                options are 
                {\tt Default}, which takes the flow from values in the matrix, 
                {\tt Canonical}, which sets the flow to 1 for each edge, and 
                {\tt Random}, which assigns a random integer between 0 and 100 to each edge
        Outputs
            Q: ToricQuiver
        Description
            Example
                Q = toricQuiver matrix({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}})
                Q = toricQuiver(matrix({{-1,-1,-1,-1},{0,0,1,1},{1,1,0,0}}), Flow=>"Random")
    Node
        Key
            (toricQuiver, Matrix, List)
        Headline
            make a toric quiver from a connectivity matrix and a flow
        Usage
            toricQuiver (M, F)
        Inputs
            M: Matrix
                of integers; each column corresponds to an arrow and each row
            F: List
                of integers specifying the flow for each arrow
        Outputs
            Q: ToricQuiver
        Description
            Example
                Q = toricQuiver(matrix({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}}), {3, 1, 0, 5})
    Node
        Key
            (toricQuiver, List)
        Headline
            make a toric quiver from a list of edges
        Usage
            toricQuiver (E)
        Inputs
            E: List
                of pairs of the form {\tt (v_1, v_2)}, one for each edge between vertices {\tt v_1} and {\tt v_2}
            Flow => String
                options are {\tt Canonical}, which sets the flow to 1 for each edge, or 
                {\tt Random}, which assigns a random integer between 0 and 100 to each edge
        Outputs
            Q: ToricQuiver
        Description
            Example
                Q = toricQuiver {{0,1},{0,1},{0,2},{0,2}}
    Node
        Key
            (toricQuiver, List, List)
        Headline
            make a toric quiver from a list of edges
        Usage
            toricQuiver (E, F)
        Inputs
            E: List
                of pairs of the form {\tt (v_1, v_2)}, one for each edge between vertices {\tt v_1} and {\tt v_2}
            F: List
                of integers specifying the flow for each arrow
        Outputs
            Q: ToricQuiver
        Description
            Example
                Q = toricQuiver ({{0,1},{0,1},{0,2},{0,2}}, {1,2,3,4})
    Node
        Key
            (toricQuiver, ToricQuiver)
        Headline
            make a toric quiver by copying
        Usage
            toricQuiver (Q)
        Inputs
            Q: ToricQuiver
        Outputs
            R: ToricQuiver
        Description
            Example
                Q = toricQuiver {{0,1},{0,1},{0,2},{0,2}}
                R = toricQuiver(Q)
    Node
        Key
            (toricQuiver, ToricQuiver, List)
        Headline
            make a toric quiver by copying
        Usage
            toricQuiver (Q, F)
        Inputs
            Q: ToricQuiver
            F: List
                of integers specifying the flow for each arrow
        Outputs
            R: ToricQuiver
        Description
            Example
                Q = toricQuiver {{0,1},{0,1},{0,2},{0,2}}
                R = toricQuiver(Q, {1,2,3,4})
    Node
        Key
            (toricQuiver, Graph)
        Headline
            make an (acyclic) toric quiver from a graph object
        Usage
            toricQuiver (G)
        Inputs
            G: Graph
        Outputs
            Q: ToricQuiver
        Description
            Text
                This algorithm creates an acyclic quiver based on the 
                undirected graph object {\tt G} by preserving the edges 
                of {\tt G} that respect the total 
                order induced by the integer-valued vertex labels
            -- Example
            --     G = completeMultipartiteGraph {1,2,3}
    Node
        Key
            (toricQuiver, Graph, List)
        Headline
            make an (acyclic) toric quiver from a graph object
        Usage
            toricQuiver (G, F)
        Inputs
            G: Graph
            F: List
                of integers specifying the flow for each edge
        Outputs
            Q: ToricQuiver
        Description
            Text
                This algorithm creates an acyclic quiver based on the 
                undirected graph object {\tt G} by preserving the edges 
                of {\tt G} that respect the total 
                order induced by the integer-valued vertex labels
    Node
        Key
            "toric quiver representation"
        Description
            Text
                toric quivers are represented as a type of HashTable with the following keys:
            Text
                @UL{  
                    {TT "connectivityMatrix: ","weighted connectivity matrix giving the vertex-edge connectivity structure of $Q$"},
                    {TT "Q0: ","list of vertices"},
                    {TT "Q1: ","list of edges"},
                    {TT "flow: ","list of integers giving the flow on each edge"},
                    {TT "weights: ","induced weights on vertices given by the image of the flow"},
                }@

            Text
                One can generate the quiver {\tt Q} associated to the bipartite graph 
                {\tt K_{2,3}} with a random flow {\tt w} as follows:

            Example
                Q0 = {{0,2},{0,3},{0,4},{1,2},{1,3},{1,4}}
                Q = toricQuiver(Q0, Flow=>"Random")
    Node
        Key
            "subquiver representation"
        Description
            Text
                There are many ways to take a subset $R=(R_0,R_1)$ of a quiver $Q=(Q_0,Q_1)$. 
                This is because we can consider $R_0\subset Q_0$ and $R_1\subset Q_1$. 
                Alternatively, $R$ is itself a quiver, with $|R_1|$ arrows and $|R_0|$ 
                vertices. Thus we can consider $R$ independently of the arrow/vertex labeling of $Q$. 

            Text
                The two methods corresponding to these ideas are referenced in the examples below. 
            Example
                Q = bipartiteQuiver(2, 3)
                Q_{0,1,3}
                Q^{0,1,3}
        SeeAlso
            (symbol ^, ToricQuiver, List)
            (symbol _, ToricQuiver, List)
    Node
        Key
            (symbol _, ToricQuiver, List)
        Headline
            taking a subquiver by indexing
        Usage
            Q_L
        Inputs
            Q: ToricQuiver
            L: List
               of integers specifying which arrows to subset
        Description
            Text
                This method returns a the subquiver of the quiver {\tt Q} 
                that is made up of the arrows in the list {\tt L}. Note that 
                this method re-orders the subquiver labels to create a standalone quiver.
                To retain the original quiver labels on the subquiver, see the SeeAlso. 
            Example
                Q = bipartiteQuiver(2, 3)
                Q_{0,1,3}
        SeeAlso
            (symbol ^, ToricQuiver, List)
    Node
        Key
            (symbol ^, ToricQuiver, List)
        Headline
            taking a subquiver by indexing
        Usage
            Q^L
        Inputs
            Q: ToricQuiver
            L: List
               of integers specifying which arrows to subset
        Description
            Text
                This method returns a the subquiver of the quiver {\tt Q} 
                that is made up of the arrows in the list {\tt L}. 
            Example
                Q = bipartiteQuiver(2, 3)
                Q^{0,1,3}
        SeeAlso
    Node
        Key
            (symbol ==, ToricQuiver, ToricQuiver)
        Headline
            comparing instances of ToricQuiver
        Usage
            Q1 == Q2
        Inputs
            Q1: ToricQuiver
            Q2: ToricQuiver
        Description
            Text
                This method takes two toric quivers and returns the 
                boolean of the statement {\tt Q1} is equal to {\tt Q2}. 
            Example
                Q = bipartiteQuiver(2, 3)
                R = bipartiteQuiver(2, 2)
                Q == R
    Node
        Key
            allSpanningTrees
        Headline
            find the spanning trees of the underlying graph
        Usage
            allSpanningTrees Q
        Inputs
            Q: ToricQuiver
        Description
            Text
                This method returns all of the spanning trees of the 
                underlying graph of the quiver {\tt Q}. Trees are 
                represented as lists of arrow indices.
            Example
                Q = bipartiteQuiver(2, 3)
                allSpanningTrees(Q)
    Node
        Key
            bipartiteQuiver
        Headline
            make a toric quiver on underlying bipartite graph
        Usage
            bipartiteQuiver (N, M)
        Inputs
            N: ZZ
                number of vertices that are sources
            M: ZZ
                number of vertices that are sinks
            Flow => 
                specify flow to use. Either a string with values {\tt Canonical} or {\tt Random}, 
                or else a list of integer values. 
        Outputs
            Q: ToricQuiver
        Description
            Text
                This function creates the unique toric quiver whose underlying graph 
                is the fully connected bipartite graph with 
                {\tt N} source vertices and {\tt M} sink vertices.
            Example
                Q = bipartiteQuiver (2, 3)
                Q = bipartiteQuiver (2, 3, Flow=>"Random")
                Q = bipartiteQuiver (2, 3, Flow=>{1, 2, 1, 3, 1, 4})
    Node
        Key
            threeVertexQuiver
        Headline
            make a toric quiver on underlying graph with three vertices and a specified number of edges between each
        Usage
            threeVertexQuiver E
        Inputs
            E: List
                number of edges between each pair of vertices
            Flow => 
                specify flow to use. Either a string with values {\tt Canonical} or {\tt Random}, 
                or else a list of integer values. 
        Outputs
            Q: ToricQuiver
        Description
            Example
                Q = threeVertexQuiver {1,2,3}
                Q = threeVertexQuiver ({1,2,3}, Flow=>"Random")
                Q = threeVertexQuiver ({1,2,3}, Flow=>{1, 2, 1, 3, 1, 4})
    Node
        Key
            chainQuiver
        Headline
            make a toric quiver on underlying graph in the form of a chain
        Usage
            chainQuiver E
        Inputs
            E: List
                number of edges linking each vertex to the next
            Flow => 
                specify flow to use. Either a string with values {\tt Canonical} or {\tt Random}, 
                or else a list of integer values. 
        Outputs
            Q: ToricQuiver
        Description
            Example
                Q = chainQuiver {1,2,3}
                Q = chainQuiver ({1,2,3}, Flow=>"Random")
                Q = chainQuiver ({1,2,3}, Flow=>{1, 2, 1, 3, 1, 4})
    Node
        Key
            incInverse
        Headline
            compute a flow in the preimage for a given weight
        Usage
            incInverse(Q, W)
        Inputs
            Q: ToricQuiver
            W: List
                of integers, specifying the weight on each vertex
        Description
            Example
                Q = toricQuiver(bipartiteQuiver(2,3));
                th = {-5,-1,2,2,2};
                incInverse(Q,th)
    Node
        Key
            isTight
        Headline
            determine if toric quiver is tight
        Usage
            isTight Q
        Inputs
            Q: ToricQuiver
        Outputs
            : Boolean
        Description
            Text
                Determines if a toric quiver {\tt Q} is tight with respect to the vertex weights induced by its flow
            Example
                isTight bipartiteQuiver(2, 3)
    Node
        Key
            (isTight, ToricQuiver)
        Headline
            determine if toric quiver is tight
        Usage
            isTight Q
        Inputs
            Q: ToricQuiver
        Outputs
            : Boolean
        Description
            Text
                Determines if a toric quiver $Q$ is tight with respect to the vertex weights induced by its flow
            Example
                isTight bipartiteQuiver(2, 3, Flow=>"Random")
    Node
        Key
            (isTight, ToricQuiver, List)
        Headline
            determine if toric quiver is tight
        Usage
            isTight(Q, W)
        Inputs
            Q: ToricQuiver
            W: List
        Outputs
            : Boolean
        Description
            Text
                Determines if a toric quiver $Q$ is tight with respect to the vertex weights induced by its flow
            Example
                isTight (bipartiteQuiver(2, 3), {2,1,2,3,2,3})
    Node
        Key
            (isTight, List, ToricQuiver)
        Headline
            determine if toric quiver is tight
        Usage
            isTight(W, Q)
        Inputs
            W: List
            Q: ToricQuiver
        Outputs
            : Boolean
        Description
            Text
                Determines if a toric quiver $Q$ is tight with respect to the vertex weights induced by its flow
            Example
                isTight ({2,1,2,3,2,3}, bipartiteQuiver(2, 3))
    Node
        Key
            makeTight
        Headline
            return a tight quiver with the same flow polytope
        Usage
            makeTight(Q, W)
        Inputs
            Q: ToricQuiver
            W: List
               of values corresponding to a weight on each arrow of Q
        Outputs
            Q: ToricQuiver
               that is tight with respect to the flow on the input, and which has the same flow polytope as the input.
        Description
            Example
                Q = bipartiteQuiver(2,3)
                w = {-5,-1,2,2,2}
                makeTight(Q,w)
    Node
        Key
            subquivers
        Headline
            return all possible subquivers of a given quiver
        Usage
            subquivers Q
        Inputs
            Q: ToricQuiver
            Format => String
                options include {\tt quiver}, which returns a list of quivers, and {\tt list}, 
                which returns a list of arrows for each subquiver
            AsSubquiver => Boolean
                if Format is specified as {\tt quiver}, then applying 
                {\tt AsSubquiver = true} insures that the matrix representation 
                of the subquiver is the same size as the matrix original quiver
        Outputs
            L: List
                of either quiver objects, or arrow indices
        Description
            Text 
                this returns the subquivers of a given quiver. 
                There are 3 main ways to represent a subquiver: 
            Text
                @UL{
                    {"as a list of arrow indices,"}, 
                    {"as a subset of rows and columns of the original connectivity matrix, and"},
                    {"as a copy of the original connectivity matrix with certain rows and columns zeroed out. "}
                }@

            Example
                Q = chainQuiver {2}
                subquivers Q
                subquivers(Q, Format=>"list")
    Node
        Key
            (subquivers, ToricQuiver)
        Headline
            return all possible subquivers of a given quiver
        Usage
            subquivers Q
        Inputs
            Q: ToricQuiver
            Format => String
                options include {\tt quiver}, which returns a list of quivers, and {\tt list}, 
                which returns a list of arrows for each subquiver
            AsSubquiver => Boolean
                if Format is specified as {\tt quiver}, then applying 
                {\tt AsSubquiver = true} insures that the matrix representation 
                of the subquiver is the same size as the matrix original quiver
        Outputs
            L: List
                of either quiver objects, or arrow indices
        Description
            Text 
                this returns the subquivers of a given quiver. 
                There are 3 main ways to represent a subquiver: 
            Text
                @UL{
                    {"as a list of arrow indices,"}, 
                    {"as a subset of rows and columns of the original connectivity matrix, and"},
                    {"as a copy of the original connectivity matrix with certain rows and columns zeroed out. "}
                }@
            Text
                These options are expanded in the Examples below. 
            Example
                subquivers bipartiteQuiver(2, 2)
                subquivers(bipartiteQuiver(2, 2), Format=>"list")
                subquivers(bipartiteQuiver(2, 2), Format=>"quiver", AsSubquiver=>true)
    Node
        Key
            isStable
        Headline
            determines if a subquiver is semistable with respect to a given weight
        Usage
            isStable (Q, L)
            isStable (Q, SQ)
        Inputs
            Q: ToricQuiver
            SQ: ToricQuiver
                A subquiver of the quiver {\tt Q}
            L: List
                of the indices of arrows in {\tt Q} that make up the subquiver in question
        Outputs
            :Boolean
        Description
            Text 
                This function determines if a given subquiver 
                is semi-stable with respect to the weight saved on {\tt Q}. 
                A subquiver {\tt SQ} of the quiver {\tt Q} is stable if for every subset 
		{\tt V} of the vertices of {\tt Q} that is also {\tt SQ}-successor closed, 
		the sum of the weights associated to {\tt V} is positive. 
            Example
                Q = bipartiteQuiver(2, 3);
                P = Q^{0,1,4,5};
                isStable(Q, P)
		
    Node
        Key
            (isStable, ToricQuiver, List)
        Headline
            determines if a subquiver is stable
        Usage
            isStable (Q, L)
        Inputs
            Q: ToricQuiver
            L: List
                of the indices of arrows in {\tt Q} that make up the subquiver in question
        Outputs
            :Boolean
        Description
            Example
                isStable (bipartiteQuiver(2, 3), {0, 1})
    Node
        Key
            (isStable, ToricQuiver, ToricQuiver)
        Headline
            determines if a subquiver is stable
        Usage
            isStable (Q, SQ)
        Inputs
            Q: ToricQuiver
            SQ: ToricQuiver
                A subquiver of the quiver $Q$
        Outputs
            :Boolean
        Description
            Example
                Q = bipartiteQuiver(2, 3)
                S = first(subquivers(Q, Format=>"quiver", AsSubquiver=>true))
                isStable (Q, S)
    Node
        Key
            isSemistable
        Headline
            determines if a subquiver is semistable with respect to a given weight
        Usage
            isSemistable (Q, L)
            isSemistable (Q, SQ)
        Inputs
            Q: ToricQuiver
            SQ: ToricQuiver
                A subquiver of the quiver {\tt Q}
            L: List
                of the indices of arrows in {\tt Q} that make up the subquiver in question
        Outputs
            :Boolean
        Description
            Text
                This function determines if a given subquiver 
                is semi-stable with respect to the weight saved on {\tt Q}. 
                A subquiver {\tt SQ} of the quiver {\tt Q} is semistable if for every subset 
		{\tt V} of the vertices of {\tt Q} that is also {\tt SQ}-successor closed, 
		the sum of the weights associated to {\tt V} is nonnegative. 
    Node
        Key
            (isSemistable, ToricQuiver, List)
        Headline
            determines if a subquiver is semistable
        Usage
            isSemistable (Q, L)
        Inputs
            Q: ToricQuiver
            L: List
                of the indices of arrows in {\tt Q} that make up the subquiver in question
        Outputs
            :Boolean
        Description
            Text 
                a subquiver {\tt SQ} of the quiver {\tt Q} is semistable if 
            Example
                isSemistable (bipartiteQuiver(2, 3), {0, 1})
    Node
        Key
            (isSemistable, ToricQuiver, ToricQuiver)
        Headline
            determines if a subquiver is semistable
        Usage
            isSemistable (Q, SQ)
        Inputs
            Q: ToricQuiver
            SQ: ToricQuiver
                A subquiver of the quiver $Q$
        Outputs
            :Boolean
        Description
            Example
                Q = bipartiteQuiver(2, 3);
                S = first(subquivers(Q, Format=>"quiver", AsSubquiver=>true))
                isSemistable (Q, S)
    Node
        Key
            stableTrees
        Headline
            return the spanning trees that are stable
        Usage
            stableTrees(th, Q)
        Inputs
            th: List
                of weights corresponding to each vertex
            Q: ToricQuiver
        Outputs
            L: List
                of lists, each representing the arrows that comprise a spanning tree that is stable with respect to the weight th
        Description
            Example
                Q = bipartiteQuiver(2,3);
                th = {-3,-3,2,2,2};
                stableTrees(th, Q)
    Node
        Key
            isAcyclic
        Headline
            check that a quiver has no cycles
        Usage
            isAcyclic Q
        Inputs
            Q: ToricQuiver
        Outputs
            :Boolean
        Description
            Text
                checks that a toric quiver does not contain any oriented cycles 
            Example
                Q = bipartiteQuiver(2, 3);
                isAcyclic Q
    Node
        Key
            (isAcyclic, ToricQuiver)
        Headline
            check that a quiver has no cycles
        Usage
            isAcyclic Q
        Inputs
            Q: ToricQuiver
        Outputs
            :Boolean
        Description
            Text
                checks that a toric quiver does not contain any oriented cycles 
            Example
                isAcyclic bipartiteQuiver(2, 3)
                isAcyclic toricQuiver matrix({{-1, 1, -1, -1}, {1, -1, 0, 0}, {0, 0, 1, 1}})
    Node
        Key
            isClosedUnderArrows
        Headline
            is a subquiver closed under arrows?
        Usage
            isClosedUnderArrows (V, Q)
        Inputs
            Q: ToricQuiver
            V: List
                set of vertices 
        Outputs
            : Boolean
        Description
            Text
                checks that a set of vertices is closed under arrows with respect to the toricQuiver {\tt Q}. 
                That is, for any $v\in V$, then any arrow in $Q_1$ with tail $v$ must have head in $V$ as well. 
                Note that this does not require that $V\subset Q_0$.
    Node
        Key
            (isClosedUnderArrows, List, ToricQuiver)
        Headline
            is a subquiver closed under arrows?
        Usage
            isClosedUnderArrows (V, Q)
        Inputs
            V: List
                set of vertices 
            Q: ToricQuiver
        Outputs
            : Boolean
        Description
            Example
                isClosedUnderArrows ({0, 2, 3}, bipartiteQuiver(2, 3))
                isClosedUnderArrows ({2, 3, 4}, bipartiteQuiver(2, 3))
    Node
        Key
            (isClosedUnderArrows, Matrix, ToricQuiver)
        Headline
            is a subquiver closed under arrows?
        Usage
            isClosedUnderArrows (M, Q)
        Inputs
            M: Matrix
                connectivity matrix of subquiver to check
            Q: ToricQuiver
        Outputs
            : Boolean
        Description
            Example
                Q = threeVertexQuiver {1, 2, 3}
                SQ = Q_{0,1}
                isClosedUnderArrows (SQ, Q)
    Node
        Key
            (isClosedUnderArrows, ToricQuiver, ToricQuiver)
        Headline
            is a subquiver closed under arrows?
        Usage
            isClosedUnderArrows (SQ, Q)
        Inputs
            SQ: ToricQuiver
                subquiver of Q to check 
            Q: ToricQuiver
        Outputs
            : Boolean
        Description
            Example
                Q = threeVertexQuiver {1, 2, 3}
                SQ = Q^{0,1}
                isClosedUnderArrows (SQ, Q)
    Node
        Key
            maximalUnstableSubquivers
        Headline
            return the maximal subquivers that are unstable
        Usage
            maximalUnstableSubquivers Q
        Inputs
            Q: ToricQuiver
            Format => String
                format for representing the subquivers
        Outputs
            L: HashTable
                consisting of two keys: {\tt Nonsingletons} and {\tt Singletons}
        Description
            Text
                this routine takes all of the possible subquivers of a given quiver {\tt Q} 
                and returns those that are both unstable and maximal with respect to the weight on the quiver {\tt Q}
            Text
                Subquivers are represented by lists of arrows, except in the case of subquivers that consist of singleton vertices. 
            Example
                maximalUnstableSubquivers bipartiteQuiver (2, 3)
    Node
        Key
            theta
        Headline
            image of the flow on the vertices
        Usage
            theta Q
        Inputs
            Q: ToricQuiver
        Outputs
            L: List
                of integers
        Description
            Text
                this is the image of the $Inc$ map 
            Example
                Q = bipartiteQuiver(2, 3, Flow=>"Random")
                theta Q
    Node
        Key
            (theta, ToricQuiver)
        Headline
            image of the flow on the vertices
        Usage
            theta Q
        Inputs
            Q: ToricQuiver
        Outputs
            L: List
                of integers
        Description
            Text
                this is the image of the $Inc$ map 
            Example
                Q = bipartiteQuiver(2, 3, Flow=>"Random")
                theta Q
    Node
        Key
            neighborliness
        Headline
            compute the neighborliness of a quiver
        Usage
            neighborliness Q
        Inputs
            Q: ToricQuiver
        Outputs
            : ZZ
        Description
            Text
                computes the neighborliness of a given quiver {\tt Q}
    Node
        Key
            (neighborliness, ToricQuiver)
        Headline
            compute the neighborliness of a quiver
        Usage
            neighborliness Q
        Inputs
            Q: ToricQuiver
        Outputs
            : ZZ
        Description
            Text
                computes the neighborliness of a given quiver {\tt Q}
            Example
                neighborliness bipartiteQuiver(2, 3)
    Node
        Key
            flowPolytope
        Headline
            generate the polytope associated to a toric quiver
        Usage
            flowPolytope(Q, F)
        Inputs
            Q: ToricQuiver
            F: List
        Outputs
            : Matrix
                giving the coordinates of the vertices defining the flow polytope
    Node
        Key
            (flowPolytope, ToricQuiver)
        Headline
            generate the polytope associated to a toric quiver
        Usage
            flowPolytope Q
        Inputs
            Q: ToricQuiver
        Outputs
            : Matrix
                giving the coordinates of the vertices defining the flow polytope
        Description
            Example
                flowPolytope(bipartiteQuiver(2, 3))
    Node
        Key
            (flowPolytope, ToricQuiver, List)
        Headline
            generate the polytope associated to a toric quiver
        Usage
            flowPolytope(Q, F)
        Inputs
            Q: ToricQuiver
            F: List
        Outputs
            : Matrix
                giving the coordinates of the vertices defining the flow polytope
        Description
            -- Example
                -- flowPolytope(bipartiteQuiver(2, 3), {2,1,2,0,1,0})
    Node
        Key
            dualFlowPolytope
        Headline
            generate the dual polytope associated to a toric quiver
        Usage
            dualFlowPolytope(Q, F)
        Inputs
            Q: ToricQuiver
            F: List
        Outputs
            : Matrix
                giving the coordinates of the vertices defining the flow polytope
        Description
    Node
        Key
            (dualFlowPolytope, ToricQuiver)
        Headline
            generate the dual polytope associated to a toric quiver
        Usage
            dualFlowPolytope Q
        Inputs
            Q: ToricQuiver
        Outputs
            : Matrix
                giving the coordinates of the vertices defining the flow polytope
        Description
            Example
                dualFlowPolytope(bipartiteQuiver(2, 3))
    Node
        Key
            (dualFlowPolytope, ToricQuiver, List)
        Headline
            generate the dual polytope associated to a toric quiver
        Usage
            dualFlowPolytope(Q, F)
        Inputs
            Q: ToricQuiver
            F: List
        Outputs
            : Matrix
                giving the coordinates of the vertices defining the flow polytope
        Description
            -- Example
                -- dualFlowPolytope(bipartiteQuiver(2, 3), {2,1,2,0,1,0})
    Node
        Key
            wallType
        Headline
            get the type of a wall for a given quiver
        Usage
            wallType (Q, Qplus)
        Inputs
            Q: ToricQuiver
            Qplus: List
        Outputs
            : 
                wall type is given by (ZZ, ZZ)
        Description
            Text
                every wall can be represented uniquely by a partition of the vertices 
                {\tt Q0} of {\tt Q} into two sets {\tt Qplus} and {\tt Qminus}. 
                We denote the wall {\tt W} by the subset of vertices {\tt Qplus} used for defining it. 
            Text
                The type of the wall is defined as {\tt (t+,t-)} where {\tt t^+} 
                is the number of arrows starting {\tt Qplus} and ending in 
                {\tt Qminus}, and {\tt t-} is the number of arrows starting {\tt Qminus} 
                and ending in {\tt Qplus}. 
            Example
                wallType(bipartiteQuiver(2, 3), {0,2,3})
    Node
        Key
            (wallType, ToricQuiver, List)
        Headline
            get the type of a wall for a given quiver
        Usage
            wallType (Q, Qplus)
        Inputs
            Q: ToricQuiver
            Qplus: List
        Outputs
            : 
                wall type is given by (ZZ, ZZ)
        Description
            Text
                every wall can be represented uniquely by a partition of the vertices 
                {\tt Q0} of {\tt Q} into two sets {\tt Qplus} and {\tt Qminus}. 
                We denote the wall {\tt W} by the subset of vertices {\tt Qplus} used for defining it. 
            Text
                The type of the wall is defined as {\tt (t+,t-)} where {\tt t^+} 
                is the number of arrows starting {\tt Qplus} and ending in 
                {\tt Qminus}, and {\tt t-} is the number of arrows starting {\tt Qminus} 
                and ending in {\tt Qplus}. 
            Example
                wallType(bipartiteQuiver(2, 3), {0,2,3})
    Node
        Key
            walls
        Headline
            return the walls in the weight chamber decomposition for a given quiver
        Usage
            walls Q
        Inputs
            Q: ToricQuiver
        Outputs
            : List
        Description
            Text
                every wall can be represented uniquely by a partition of the vertices 
                {\tt Q0} of {\tt Q} into two sets {\tt Qplus} and {\tt Qminus}. As a partition 
                can be expressed in terms of only one of the subsets, only one of the two sets {\tt Qplus} 
                and {\tt Qminus} is used in every case. 
                Thus we denote the wall {\tt W} by the subset of vertices {\tt Qplus} used for defining it. 
            Example
                Q = toricQuiver {{0,1},{0,2},{0,3},{1,2},{1,3},{2,3}}
                walls Q
    Node
        Key
            (walls, ToricQuiver)
        Headline
            return the walls in the weight chamber decomposition for a given quiver
        Usage
            walls Q
        Inputs
            Q: ToricQuiver
        Outputs
            : List
        Description
            Text
                each wall is given in the form $(t^+,t^-), Q^+$, where $(t^+,t^-)$ is 
                the wall type associated to the wall with vertex-partition $Q_0=Q^+\cup (Q_0\setminus Q^+)$
            Example
                Q = toricQuiver {{0,1},{0,2},{0,3},{1,2},{1,3},{2,3}}
                walls Q
    Node
        Key
            mergeOnVertex
        Headline
            join two quivers together by identifying a vertex from each
        Usage
            mergeOnVertex (Q1, V1, Q2, V2)
        Inputs
            Q1: ToricQuiver
            V1: ZZ
            Q2: ToricQuiver
            V2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying 
                vertex $V1$ in $Q1$ with vertex $V2$ in $Q2$. 
            Example
                mergeOnVertex (bipartiteQuiver (2, 3), 1, bipartiteQuiver (2, 3), 0)
    Node
        Key
            (mergeOnVertex, ToricQuiver, ZZ, ToricQuiver, ZZ)
        Headline
            join two quivers together by identifying a vertex from each
        Usage
            mergeOnVertex (Q1, V1, Q2, V2)
        Inputs
            Q1: ToricQuiver
            V1: ZZ
            Q2: ToricQuiver
            V2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying vertex $V1$ in $Q1$ with vertex $V2$ in $Q2$. 
            Example
                mergeOnVertex (bipartiteQuiver (2, 3), 1, bipartiteQuiver (2, 3), 0)
    Node
        Key
            (mergeOnVertex, ToricQuiver, ZZ, Matrix, ZZ)
        Headline
            join two quivers together by identifying a vertex from each
        Usage
            mergeOnVertex (Q1, V1, Q2, V2)
        Inputs
            Q1: ToricQuiver
            V1: ZZ
            Q2: Matrix
            V2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying vertex $V1$ in $Q1$ with vertex $V2$ in $Q2$. 
            Example
                mergeOnVertex (bipartiteQuiver (2, 3), 1, matrix({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}}), 0)
    Node
        Key
            (mergeOnVertex, Matrix, ZZ, ToricQuiver, ZZ)
        Headline
            join two quivers together by identifying a vertex from each
        Usage
            mergeOnVertex (Q1, V1, Q2, V2)
        Inputs
            Q1: Matrix
            V1: ZZ
            Q2: ToricQuiver
            V2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying vertex $V1$ in $Q1$ with vertex $V2$ in $Q2$. 
            Example
                mergeOnVertex (matrix({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}}), 1, bipartiteQuiver (2, 3), 0)
    Node
        Key
            mergeOnArrow
        Headline
            join two quivers together by identifying an arrow from each
        Usage
            mergeOnArrow (Q1, A1, Q2, A2)
        Inputs
            Q1: ToricQuiver
            A1: ZZ
            Q2: ToricQuiver
            A2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying arrow $A1$ in $Q1$ with arrow $A2$ in $Q2$. 
            Example
                mergeOnArrow (bipartiteQuiver (2, 3), 0, bipartiteQuiver (2, 3), 0)
    Node
        Key
            (mergeOnArrow, ToricQuiver, ZZ, ToricQuiver, ZZ)
        Headline
            join two quivers together by identifying an arrow from each
        Usage
            mergeOnArrow (Q1, A1, Q2, A2)
        Inputs
            Q1: ToricQuiver
            A1: ZZ
            Q2: ToricQuiver
            A2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying arrow $A1$ in $Q1$ with arrow $A2$ in $Q2$. 
            Example
                mergeOnArrow (bipartiteQuiver (2, 3), 0, bipartiteQuiver (2, 3), 0)
    Node
        Key
            (mergeOnArrow, ToricQuiver, ZZ, Matrix, ZZ)
        Headline
            join two quivers together by identifying an arrow from each
        Usage
            mergeOnArrow (Q1, A1, Q2, A2)
        Inputs
            Q1: ToricQuiver
            A1: ZZ
            Q2: Matrix
            A2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying arrow $A1$ in $Q1$ with arrow $A2$ in $Q2$. 
            Example
                mergeOnArrow (bipartiteQuiver (2, 3), 0, matrix({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}}), 0)
    Node
        Key
            (mergeOnArrow, Matrix, ZZ, ToricQuiver, ZZ)
        Headline
            join two quivers together by identifying an arrow from each
        Usage
            mergeOnArrow (Q1, A1, Q2, A2)
        Inputs
            Q1: Matrix
            A1: ZZ
            Q2: ToricQuiver
            A2: ZZ
        Outputs
            : ToricQuiver
        Description
            Text
                create a new quiver from joining two toricQuivers together by identifying arrow $A1$ in $Q1$ with arrow $A2$ in $Q2$. 
            Example
                mergeOnArrow (matrix ({{-1,-1,-1,-1},{1,1,0,0},{0,0,1,1}}), 0, bipartiteQuiver (2, 3), 0)
///
end--
