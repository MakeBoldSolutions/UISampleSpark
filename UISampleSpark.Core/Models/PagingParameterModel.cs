
namespace UISampleSpark.Core.Models;
/// <summary>
/// Paging Parameter Model
/// </summary>
public class PagingParameterModel
{
    private const int maxPageSize = 5000;
    private int? _pageSize { get; set; }
    public PagingParameterModel()
    {
        _pageSize = 300;
        PageNumber = 1;
    }
    public object GetMetaData(long TotalCount)
    {
        var pageSize = PageSize ?? 300;
        var pageNumber = PageNumber ?? 1;
        return new
        {
            totalCount = TotalCount,
            pageSize = pageSize,
            currentPage = pageNumber,
            totalPages = (int)Math.Ceiling(TotalCount / (double)pageSize),
            previousPage = pageNumber > 1 ? "Yes" : "No",
            nextPage = pageNumber < (int)Math.Ceiling(TotalCount / (double)pageSize) ? "Yes" : "No"
        };
    }

    /// <summary>
    /// 1-based page number. Defaults to 1.
    /// </summary>
    public int? PageNumber { get; set; }

    /// <summary>
    /// Number of records per page. Capped at 5 000; defaults to 300.
    /// </summary>
    public int? PageSize
    {
        get { return _pageSize; }
        set { _pageSize = value > maxPageSize ? maxPageSize : value; }
    }
}
