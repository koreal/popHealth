class ReportsController < ApplicationController

  # todo: this needs to be a final (immutable) variable
  @@valid_parameters = [:gender, :age, :medications, :blood_pressures, 
                        :therapies, :diabetes, :smoking, :hypertension, 
                        :ischemic_vascular_disease, :lipoid_disorder, 
                        :ldl_cholesterol, :colorectal_cancer_screening,
                        :mammography, :influenza_vaccine, :hb_a1c]
  
  # GET /reports
  def index
    if params[:id]
      response = ""
      begin
            @report = Report.find_and_populate(params[:id])
            @report.save!
            resp = {}
            resp = @report.to_json_hash
            load_report_data(Report.merge_popconnect_request(@report.denominator_query, @report.numerator_query), resp)
            response = resp.to_json
      #rescue => e
      #  response = "#{e}".to_json
      end
       render :json => response
    else
      # load the sidebar summary information
      response = ""
      begin
        @reports = Report.all_and_populate(:order => 'title asc')
        resp = {
          "populationCount" => Report.patient_count,
          "populationName" => "Sagacious Healthcare Services",
          "reports" => @reports
        }
        response = resp.to_json
      #rescue => e
      #  response = "#{e}".to_json
      end
      render :json => response
    end
  end

  # POST /reports
  def create
    resp = {}
    response = ""
    begin
     @report = Report.create_and_populate(params) 
     resp = @report.to_json_hash
     resp = load_report_data(Report.merge_popconnect_request(@report.denominator_query, @report.numerator_query), resp)
     response = resp.to_json
    #rescue => e
    #  response = "#{e}".to_json
    end
    render :json => response
  end
  
  def pqri_report
    @report = Report.find(params[:id])
    render 'pqri_report.xml', :layout => false
  end

  private
  
  def load_report_data(report_parameters, resp = {})
    resp[:count] = Report.patient_count
    report_id_array = Report.patient_count_with_ids(report_parameters)
    FieldConfiguration.find(:all).each { |field|
      bar_lengths = Hash.new
      0.upto(field.bins.length - 1) { |i|
        bar_lengths[field.bins[i]] = [ReportDataCalculator.get_bar_length(field.symbol, i, report_id_array), 
                                      ReportDataCalculator.get_bar_length(field.symbol, i)] 
      }  
      resp[field.symbol] = bar_lengths
    }
    resp
  end
  
end